defmodule Api.Pipeline.RerankStage do
  @rerank_prompt """
  You are a relevance scoring assistant.
  Given a question and a list of documents (each with a title and description),
  rate each document's relevance to the question on a scale from 0.0 to 1.0.
  Return exactly one score per document, in the SAME ORDER as provided.
  """

  @output_format %{
    name: "rerank_schema",
    schema: %{
      type: "object",
      properties: %{
        scores: %{
          type: "array",
          items: %{type: "number"},
          description:
            "Relevance score (0.0–1.0) for each document, in the same order they were provided."
        }
      },
      required: ["scores"],
      additionalProperties: false
    },
    type: "json_schema"
  }

  @doc """
  Reranks `articles` by relevance to `normalized_query` and returns the top documents.
  When `config.rerank_double_pass_enabled` is true, two parallel passes (normal + reversed document order)
  are run and their scores averaged before ranking.

  Returns `{:ok, top_articles, total_cost}` or `{:error, reason}`.
  """
  def run(_normalized_query, articles) when articles == [], do: {:ok, [], 0.0}

  def run(normalized_query, articles, config) do
    if config.rerank_double_pass_enabled do
      run_double_rerank(normalized_query, articles, config)
    else
      run_single_rerank(normalized_query, articles, config)
    end
  end

  defp run_single_rerank(normalized_query, articles, config) do
    with {:ok, scores, cost} <- score_articles(normalized_query, articles, config) do
      top = select_top(articles, scores, config)
      Api.Pipeline.Debug.log("RerankStage/scores", Enum.zip(Enum.map(articles, & &1.title), scores))
      Api.Pipeline.Debug.log("RerankStage/top_articles", Enum.map(top, & &1.title))
      {:ok, top, cost}
    end
  end

  defp run_double_rerank(normalized_query, articles, config) do
    reversed = Enum.reverse(articles)

    task1 = Task.async(fn -> score_articles(normalized_query, articles, config) end)
    task2 = Task.async(fn -> score_articles(normalized_query, reversed, config) end)

    result1 = Task.await(task1, 60_000)
    result2 = Task.await(task2, 60_000)

    with {:ok, scores1, cost1} <- result1,
         {:ok, scores2_reversed, cost2} <- result2 do
      # Reverse pass2 scores back to align with original article order
      scores2 = Enum.reverse(scores2_reversed)

      averaged =
        Enum.zip(scores1, scores2)
        |> Enum.map(fn {s1, s2} -> (s1 + s2) / 2.0 end)

      top = select_top(articles, averaged, config)
      Api.Pipeline.Debug.log("RerankStage/scores_pass1", Enum.zip(Enum.map(articles, & &1.title), scores1))
      Api.Pipeline.Debug.log("RerankStage/scores_pass2", Enum.zip(Enum.map(articles, & &1.title), scores2))
      Api.Pipeline.Debug.log("RerankStage/scores_averaged", Enum.zip(Enum.map(articles, & &1.title), averaged))
      Api.Pipeline.Debug.log("RerankStage/top_articles", Enum.map(top, & &1.title))

      {:ok, top, cost1 + cost2}
    end
  end

  defp score_articles(normalized_query, articles, config) do
    key = config.api_key

    options = %Api.Provider.Options{
      model: config.rerank_model,
      temperature: config.rerank_temperature,
      top_p: config.rerank_top_p,
      reasoning_enabled: false,
      format: @output_format
    }

    docs_text =
      articles
      |> Enum.with_index(1)
      |> Enum.map(fn {article, i} ->
        "[#{i}] Title: #{article.title}\nDescription: #{article.description}"
      end)
      |> Enum.join("\n\n")

    input =
      "Question: #{normalized_query}\n\nDocuments:\n#{docs_text}\n\n#{@rerank_prompt}"

    Api.Pipeline.EmbeddingRetrieval.retry(fn ->
      case Api.Provider.OpenRouter.generate_response(key, input, options) do
        {:ok, response} ->
          result = Jason.decode!(response.content)
          scores = result["scores"]

          if length(scores) != length(articles) do
            {:error, "Reranker returned #{length(scores)} scores for #{length(articles)} documents"}
          else
            {:ok, scores, response.metadata.total_cost}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end, 3)
  end

  defp select_top(articles, scores, config) do
    Enum.zip(articles, scores)
    |> Enum.sort_by(fn {_article, score} -> score end, :desc)
    |> Enum.take(config.rerank_top_k)
    |> Enum.map(fn {article, _score} -> article end)
  end
end
