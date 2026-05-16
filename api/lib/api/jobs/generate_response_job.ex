defmodule Api.Workers.GenerateResponseJob do
  use Oban.Worker,
    queue: :default,
    max_attempts: 1

  defp query_openrouter(key, messages, model, props) do
    config = %{
      openrouter_api_url: System.get_env("OPENROUTER_API_URL") || "https://openrouter.ai/api/v1"
    }

    query_params = Map.merge(%{messages: messages, model: model}, props)

    case Req.post(
           url: config.openrouter_api_url <> "/chat/completions",
           headers: [
             Authorization: "Bearer " <> key,
             "Content-Type": "application/json"
           ],
           json: query_params
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
           Api.Message.new(%{
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

  defp get_conversation_history(chat_id, user_id) do
    with {:ok, messages} <- Api.Message.get_by_chat_id(chat_id, user_id) do
      {:ok,
       messages
       |> Enum.filter(fn message -> message.role in ["user", "assistant"] end)
       |> Enum.sort_by(& &1.inserted_at)
       |> Enum.map(
         &%{
           role: &1.role,
           content: &1.content
         }
       )}
    else
      _ -> {:error, "Failed to retrieve conversation history"}
    end
  end

  defp generate_response(api_key, message) do
    with {:ok, conversation_history} <-
           get_conversation_history(message["chat_id"], message["author_id"]) do
      case query_openrouter(api_key, conversation_history, "gpt-4.1-mini", %{}) do
        {:ok, response} ->
          {:ok,
           response
           |> Map.get("choices")
           |> List.first()
           |> Map.get("message")
           |> Map.get("content")}

        {:error, reason} ->
          {:error, reason}
      end
    else
      _ ->
        {:error, "Failed to generate response from OpenRouter"}
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
    with {:ok, initial_message} <- create_initial_message(args["message"]),
         :ok <- broadcast_generating_response(initial_message, args["message"]["author_id"]) do
      with {:ok, response} <- generate_response(args["api_key"], args["message"]),
           {:ok, complete_message} <-
             Api.Message.update_by_id(initial_message.id, %{
               content: response,
               role: "assistant"
             }),
           :ok <- broadcast_response_complete(complete_message, args["message"]["author_id"]) do
        :ok
      else
        {_, reason} ->
          with {:ok, complete_message} <-
                 Api.Message.update_by_id(initial_message.id, %{
                   content: "An error occurred while generating the response.",
                   role: "error"
                 }) do
            broadcast_response_complete(complete_message, args["message"]["author_id"])
          end

          {:error, reason}
      end
    else
      {_, reason} ->
        {:error, reason}
    end
  end
end
