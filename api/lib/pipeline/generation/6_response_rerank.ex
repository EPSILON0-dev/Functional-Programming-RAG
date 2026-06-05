defmodule Api.Pipeline.ResponseRerank do
  @rerank_prompt """
  You are a response quality evaluator.
  Given a question and a list of candidate responses, select the single best response.
  The best response should be accurate, complete, well-structured, and directly address the question.
  Return the 1-based index of the best response and a brief reasoning for your choice.
  """

  @output_format %{
    name: "response_rerank_schema",
    schema: %{
      type: "object",
      properties: %{
        best_index: %{
          type: "integer",
          description: "1-based index of the best response."
        },
        reasoning: %{
          type: "string",
          description: "Brief explanation for why this response was selected."
        }
      },
      required: ["best_index", "reasoning"],
      additionalProperties: false
    },
    type: "json_schema"
  }

  @doc """
  Selects the best candidate response for the given `question`.

  `candidates` is a list of `%{content: String.t(), cost: float()}` maps
  as returned by `Api.Pipeline.Generation.run/3`.

  When only one candidate is provided, it is returned directly without an LLM call.

  Returns `{:ok, %{response: String.t(), reasoning: String.t(), cost: float()}}` or `{:error, reason}`.
  """
  def run(_question, [single]) do
    {:ok, %{response: single.content, reasoning: "Only one candidate.", cost: 0.0}}
  end

  def run(question, candidates, config) do
    key = config.api_key

    options = %Api.Provider.Options{
      model: config.response_rerank_model,
      temperature: config.response_rerank_temperature,
      top_p: config.response_rerank_top_p,
      reasoning_enabled: false,
      format: @output_format
    }

    responses_text =
      candidates
      |> Enum.with_index(1)
      |> Enum.map(fn {candidate, i} -> "[#{i}]\n#{candidate.content}" end)
      |> Enum.join("\n\n")

    input =
      "Question: #{question}\n\nCandidate Responses:\n#{responses_text}\n\n#{@rerank_prompt}"

    case Api.Provider.OpenRouter.generate_response(key, input, options) do
      {:ok, response} ->
        result = Jason.decode!(response.content)
        index = result["best_index"] - 1

        case Enum.at(candidates, index) do
          nil ->
            {:error,
             "Response reranker returned out-of-range index #{result["best_index"]} for #{length(candidates)} candidates"}

          best ->
            result_map = %{
              response: best.content,
              reasoning: result["reasoning"],
              cost: response.metadata.total_cost
            }

            Api.Pipeline.Debug.log("ResponseRerank", %{selected_index: result["best_index"], reasoning: result["reasoning"]})
            {:ok, result_map}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
