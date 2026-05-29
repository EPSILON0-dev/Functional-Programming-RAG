defmodule Api.Pipeline.Generation do
  # Number of candidate responses to generate in parallel.
  @parallel_generations 2

  @llm_model "openai/gpt-4.1"

  @generation_options %Api.Provider.Options{
    temperature: 0.7,
    top_p: 0.95,
    presence_penalty: 0.1,
    frequency_penalty: 0.0,
    reasoning_enabled: true,
    reasoning_effort: "low"
  }

  @system_prompt_prefix """
  You are a helpful assistant with access to a curated knowledge base.
  Use the following articles to answer the user's question.
  Base your response on the provided articles; supplement with general knowledge only when
  the articles are insufficient, and indicate clearly when you do so.

  Knowledge Base Articles:
  """

  @doc """
  Generates `@parallel_generations` candidate responses using the conversation history,
  the current question, and the top reranked articles.

  `conversation_history` is a list of `%{role: "user"|"assistant", content: String.t()}` maps
  NOT including the current `question`.

  Returns `{:ok, candidates, total_cost}` where `candidates` is a list of
  `%{content: String.t(), cost: float()}` maps, or `{:error, reason}`.
  """
  def run(conversation_history, question, articles) do
    key = System.get_env("OPENROUTER_API_KEY") || ""

    options = %Api.Provider.Options{
      @generation_options
      | model: @llm_model
    }

    system_prompt = @system_prompt_prefix <> format_articles(articles)

    input =
      [%{role: "system", content: system_prompt}] ++
        conversation_history ++
        [%{role: "user", content: question}]

    tasks =
      for _ <- 1..@parallel_generations do
        Task.async(fn -> Api.Provider.OpenRouter.generate_response(key, input, options) end)
      end

    results = Task.await_many(tasks, 120_000)

    {successes, failures} =
      Enum.split_with(results, fn
        {:ok, _} -> true
        _ -> false
      end)

    if successes == [] do
      [{:error, reason} | _] = failures
      {:error, reason}
    else
      candidates =
        Enum.map(successes, fn {:ok, response} ->
          %{content: response.content, cost: response.metadata.total_cost}
        end)

      Api.Pipeline.Debug.log(
        "Generation/candidates",
        candidates |> Enum.with_index(1) |> Enum.map(fn {c, i} -> %{index: i, content: c.content} end)
      )

      total_cost = Enum.reduce(candidates, 0.0, fn c, acc -> acc + c.cost end)
      {:ok, candidates, total_cost}
    end
  end

  defp format_articles(articles) do
    articles
    |> Enum.with_index(1)
    |> Enum.map(fn {article, i} ->
      """
      --- Article #{i}: #{article.title} ---
      #{article.description}

      #{article.content}
      """
    end)
    |> Enum.join("\n")
  end
end
