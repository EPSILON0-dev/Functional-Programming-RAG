defmodule Api.Pipeline.TopicExtraction do
  @llm_model "openai/gpt-4.1-mini"

  @generation_options %Api.Provider.Options{
    temperature: 0.1,
    top_p: 0.9,
    presence_penalty: 0.0,
    frequency_penalty: 0.0,
    reasoning_enabled: false
  }

  @system_prompt """
  You are an assistant that analyzes user questions in the context of a conversation.
  Perform the following tasks:
   1. Determine whether a knowledge base lookup is needed to properly answer the question.
      Provide a score from 0.0 (no lookup needed) to 1.0 (lookup definitely needed) and a brief reason.
  Notes:
   * Questions about facts, technical topics, or specific domain knowledge typically need a KB lookup.
   * Simple conversational replies, greetings, or questions answerable from general knowledge do not.
   2. Rewrite the question to be fully self-contained: replace all pronouns and references
      to prior messages with the actual entities they refer to.
   3. Extract a concise list of search keywords from the question suitable for document retrieval.
  """

  @output_format %{
    name: "topic_extraction_schema",
    schema: %{
      type: "object",
      properties: %{
        kb_needed_score: %{
          type: "number",
          description:
            "Score from 0.0 to 1.0 indicating whether a knowledge base lookup is needed (0.0 = not needed, 1.0 = definitely needed)."
        },
        kb_needed_reason: %{
          type: "string",
          description: "Brief explanation for the kb_needed_score."
        },
        normalized_query: %{
          type: "string",
          description:
            "The question rewritten to be fully self-contained without references to conversation history."
        },
        keywords: %{
          type: "array",
          items: %{type: "string"},
          description: "Search keywords extracted from the question for knowledge base retrieval."
        }
      },
      required: ["kb_needed_score", "kb_needed_reason", "normalized_query", "keywords"],
      additionalProperties: false
    },
    type: "json_schema"
  }

  @kb_needed_threshold 0.5

  @doc """
  Analyzes the question in context of conversation history.
  `conversation_history` is a list of `%{role: "user"|"assistant", content: String.t()}` maps
  NOT including the current `question`.

  Returns `{:ok, result}` where result has keys:
    - `:kb_needed` — boolean, whether to query the knowledge base
    - `:kb_score` — float 0–1
    - `:kb_reason` — string
    - `:normalized_query` — self-contained rewrite of the question
    - `:keywords` — list of strings
    - `:cost` — float, total API cost
  """
  def run(conversation_history, question) do
    key = System.get_env("OPENROUTER_API_KEY") || ""

    options = %Api.Provider.Options{
      @generation_options
      | model: @llm_model,
        format: @output_format
    }

    input =
      [%{role: "system", content: @system_prompt}] ++
        conversation_history ++
        [%{role: "user", content: question}]

    case Api.Provider.OpenRouter.generate_response(key, input, options) do
      {:ok, response} ->
        result = Jason.decode!(response.content)
        Api.Pipeline.Debug.log("TopicExtraction", result)

        {:ok,
         %{
           kb_needed: result["kb_needed_score"] >= @kb_needed_threshold,
           kb_score: result["kb_needed_score"],
           kb_reason: result["kb_needed_reason"],
           normalized_query: result["normalized_query"],
           keywords: result["keywords"],
           cost: response.metadata.total_cost
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
