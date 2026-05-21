defmodule Api.Workers.GenerateTitleJob do
  use Oban.Worker,
    queue: :default,
    max_attempts: 1

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

  # TODO: Use a structured response
  defp get_conversation_string(chat_id, user_id) do
    with {:ok, conversation_history} <- get_conversation_history(chat_id, user_id) do
      query =
        (conversation_history
         |> Enum.reduce("", fn message, acc ->
           acc <> "#{message.role}: #{message.content}\n\n"
         end)) <>
          "Based on the above conversation, generate a concise and descriptive title that captures the main topic or theme of the discussion. Keep it short like \"Question about cars\", don't put the title in quotes, do not describe what's happening, just give the topic name"

      {:ok, query}
    else
      _ -> {:error, "Failed to construct conversation string"}
    end
  end

  defp generate_title(api_key, chat_id, user_id) do
    with {:ok, query} <- get_conversation_string(chat_id, user_id) do
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

  defp broadcast_rename(chat_id, user_id, chat_name) do
    ApiWeb.Endpoint.broadcast("user:#{user_id}", "chat_rename", %{
      chat_id: chat_id,
      chat_name: chat_name
    })
  end

  defp handle_rename(chat_id, user_id, new_name) do
    with {:ok, _} <- Api.Chat.rename_by_id(chat_id, user_id, new_name) do
      IO.inspect(new_name, label: "Generated Title")
      broadcast_rename(chat_id, user_id, new_name)
      {:ok, "Chat renamed successfully"}
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    IO.inspect(args, label: "GenerateTitleJob Args")
    #
    # Step 1: Generate title using OpenRouter
    with {:ok, response} <- generate_title(args["api_key"], args["chat_id"], args["user_id"]) do
      #
      # Step 2: Update chat with generated title and broadcast to user
      handle_rename(args["chat_id"], args["user_id"], response.content)
    else
      {_, reason} ->
        {:error, reason}
    end
  end
end
