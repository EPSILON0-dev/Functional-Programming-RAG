defmodule Api.Pipeline.UninformedResponse do
  @llm_model "openai/gpt-4.1"

  @generation_options %Api.Provider.Options{
    temperature: 0.7,
    top_p: 0.95,
    presence_penalty: 0.0,
    frequency_penalty: 0.0,
    reasoning_enabled: false
  }

  @system_prompt """
  You are a helpful and knowledgeable assistant. Assisting in learning functional programming.
  Answer the user's question based on the conversation history and your general knowledge.
  Do not reference or rely on any external documents or knowledge bases.
  Be concise, accurate, and direct.
  """

  @doc """
  Generates a response to the question without knowledge base context.
  `conversation_history` is a list of `%{role: "user"|"assistant", content: String.t()}` maps
  NOT including the current `question`.

  Returns `{:ok, %{response: String.t(), cost: float()}}` or `{:error, reason}`.
  """
  def run(conversation_history, question) do
    key = System.get_env("OPENROUTER_API_KEY") || ""

    options = %Api.Provider.Options{
      @generation_options
      | model: @llm_model
    }

    input =
      [%{role: "system", content: @system_prompt}] ++
        conversation_history ++
        [%{role: "user", content: question}]

    case Api.Provider.OpenRouter.generate_response(key, input, options) do
      {:ok, response} ->
        Api.Pipeline.Debug.log("UninformedResponse", response.content)
        {:ok, %{response: response.content, cost: response.metadata.total_cost}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
