defmodule Api.Workers.GenerateResponseJob do
  use Oban.Worker,
    queue: :default,
    max_attempts: 1

  # If the message gets read from the database, it will be read as an error
  # Message sent via the socket will be read as generating
  # When the generation is complete, the message will be updated

  defp query_openrouter(query, model, props) do
    # Hardcoding :D
    config = %{
      openrouter_api_url: System.get_env("OPENROUTER_API_URL") || "https://openrouter.ai/api/v1",
      openrouter_api_key: System.get_env("OPENROUTER_API_KEY") || "sk-xxx"
    }

    case Req.post(
           url: config.openrouter_api_url <> "/responses",
           headers: [
             Authorization: "Bearer " <> config.openrouter_api_key,
             "Content-Type": "application/json"
           ],
           json: Map.merge(%{input: query, model: model}, props)
         ) do
      {:ok, resp} ->
        if resp.status == 200 do
          {:ok, resp.body}
        else
          {:error, "OpenRouter API returned status #{resp.status}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_initial_message(args) do
    with {:ok, initial_message} <-
           Api.Message.new_message(%{
             "content" => "",
             "role" => "generating",
             "chat_id" => args["chat_id"],
             "author_id" => nil
           }) do
      {:ok, initial_message}
    else
      _ -> {:error, "Failed to create initial message"}
    end
  end

  defp broadcast_generating_response(initial_message, user_id) do
    ApiWeb.Endpoint.broadcast("user:#{user_id}", "response_new", %{
      id: initial_message.id,
      role: initial_message.role,
      chat_id: initial_message.chat_id,
      timestamp: initial_message.inserted_at
    })
  end

  defp generate_response(args) do
    case query_openrouter(args["content"], "gpt-4.1-mini", %{}) do
      {:ok, response} ->
        {:ok,
         response
         |> Map.get("output")
         |> List.first()
         |> Map.get("content")
         |> List.first()
         |> Map.get("text")}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, "Failed to generate response"}
    end
  end

  defp broadcast_response_complete(complete_message, user_id) do
    ApiWeb.Endpoint.broadcast("user:#{user_id}", "response_complete", %{
      id: complete_message.id,
      role: complete_message.role,
      content: complete_message.content,
      chat_id: complete_message.chat_id,
      timestamp: complete_message.inserted_at
    })
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    with {:ok, initial_message} <- create_initial_message(args),
         :ok <- broadcast_generating_response(initial_message, args["author_id"]),
         {:ok, response} <- generate_response(args),
         {:ok, complete_message} <-
           Api.Message.update_message(initial_message.id, %{
             content: response,
             role: "assistant"
           }),
         :ok <- broadcast_response_complete(complete_message, args["author_id"]) do
      :ok
    else
      _ ->
        IO.puts("GenerateResponseJob error")
        {:error, "Failed to generate response"}
    end
  end
end
