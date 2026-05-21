defmodule Api.Workers.GenerateResponseJob do
  use Oban.Worker,
    queue: :default,
    max_attempts: 1

  defp broadcast_generating_response(initial_message, user_id) do
    ApiWeb.Endpoint.broadcast("user:#{user_id}", "response_new", %{
      id: initial_message.id,
      role: initial_message.role,
      chat_id: initial_message.chat_id,
      timestamp: initial_message.inserted_at
    })
  end

  defp create_initial_message(args) do
    with {:ok, initial_message} <-
           Api.Message.new(%{
             "content" => "",
             "role" => "generating",
             "chat_id" => args["chat_id"],
             "author_id" => nil
           }),
         broadcast_generating_response(initial_message, args["author_id"]) do
      {:ok, initial_message}
    else
      _ -> {:error, "Failed to create initial message"}
    end
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

  defp get_conversation_string(chat_id, user_id) do
    with {:ok, conversation_history} <- get_conversation_history(chat_id, user_id) do
      {:ok,
       (conversation_history
        |> Enum.reduce("", fn message, acc ->
          acc <> "#{message.role}: #{message.content}\n\n"
        end)) <> "assistant:"}
    else
      _ -> {:error, "Failed to construct conversation string"}
    end
  end

  defp generate_response(api_key, message) do
    with {:ok, query} <- get_conversation_string(message["chat_id"], message["author_id"]) do
      options = %Model.Provider.Options{model: "gpt-4o"}

      case Model.Provider.OpenRouter.generate_response(api_key, query, options) do
        {:ok, response} -> {:ok, response}
        {:error, reason} -> {:error, reason}
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

  defp handle_completion(response, message_id, user_id) do
    message = %{
      content: response.content,
      metadata:
        Map.merge(Map.from_struct(response.metadata), %{
          "reasoning" => response.reasoning
        }),
      role: "assistant"
    }

    with {:ok, complete_message} <- Api.Message.update_by_id(message_id, message) do
      broadcast_response_complete(complete_message, user_id)
    end
  end

  defp handle_error(reason, message_id, user_id) do
    with {:ok, complete_message} <-
           Api.Message.update_by_id(message_id, %{
             content: "An error occurred while generating the response.",
             role: "error"
           }) do
      broadcast_response_complete(complete_message, user_id)
    end

    {:error, reason}
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    with {:ok, initial_message} <- create_initial_message(args["message"]) do
      with {:ok, response} <- generate_response(args["api_key"], args["message"]) do
        handle_completion(response, initial_message.id, args["message"]["author_id"])
      else
        {_, reason} ->
          handle_error(reason, initial_message.id, args["message"]["author_id"])
          {:error, reason}
      end
    else
      {_, reason} ->
        {:error, reason}
    end
  end
end
