defmodule Api.Pipeline.UninformedResponse do
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
  def run(conversation_history, question, config) do
    key = config.api_key

    options = %Api.Provider.Options{
      model: config.uninformed_response_model,
      temperature: config.uninformed_response_temperature,
      top_p: config.uninformed_response_top_p,
      presence_penalty: 0.0,
      frequency_penalty: 0.0,
      reasoning_enabled: false
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
