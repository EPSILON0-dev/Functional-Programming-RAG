defmodule Api.Pipeline.EmbeddingRetrieval do
  import Ecto.Query
  import Pgvector.Ecto.Query

  @doc """
  Retry a function up to `max_attempts` times (default 3).
  Expects the function to return a tuple starting with `:ok` or `:error`.
  Returns the first successful result, or the final error-tuple.
  """
  def retry(func, max_attempts \\ 3) when is_function(func, 0) and max_attempts > 0 do
    do_retry(func, max_attempts, {:error, "All retries exhausted"})
  end

  defp do_retry(_func, 0, last_result), do: last_result

  defp do_retry(func, attempts_left, _last_result) do
    case func.() do
      {:ok, _, _} = success -> success
      {:ok, _} = success -> success
      {:error, _} = error -> do_retry(func, attempts_left - 1, error)
    end
  end

  @doc """
  Retrieves relevant articles using vector similarity search.
  Embeds both the `question` and the `uninformed_response` (HyDE), then searches
  against both content and description embeddings. Results are deduplicated by article ID.

  Returns `{:ok, articles, total_cost}` or `{:error, reason}`.
  """
  def run(question, uninformed_response, config) do
    key = config.api_key
    model = config.embedding_model

    with {:ok, query_embedding} <-
           Api.Provider.OpenRouter.generate_embedding(key, question, model),
         {:ok, response_embedding} <-
           Api.Provider.OpenRouter.generate_embedding(key, uninformed_response, model) do
      q_vec = Pgvector.new(query_embedding.embedding)
      r_vec = Pgvector.new(response_embedding.embedding)

      articles =
        (search_by_content(q_vec, config) ++
           search_by_description(q_vec, config) ++
           search_by_content(r_vec, config) ++
           search_by_description(r_vec, config))
        |> Enum.uniq_by(& &1.id)

      Api.Pipeline.Debug.log("EmbeddingRetrieval", Enum.map(articles, & &1.title))

      total_cost = query_embedding.cost + response_embedding.cost
      {:ok, articles, total_cost}
    end
  end

  defp search_by_content(vec, config) do
    from(a in Api.Article,
      where: not is_nil(a.content_embedding),
      order_by: cosine_distance(a.content_embedding, ^vec),
      limit: ^config.per_search_limit
    )
    |> Api.Repo.all()
  end

  defp search_by_description(vec, config) do
    from(a in Api.Article,
      where: not is_nil(a.description_embedding),
      order_by: cosine_distance(a.description_embedding, ^vec),
      limit: ^config.per_search_limit
    )
    |> Api.Repo.all()
  end
end
