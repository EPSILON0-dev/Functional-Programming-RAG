defmodule ApiWeb.Controllers.ChatController do
  use ApiWeb, :controller

  defp get_conversation_history(chat_id, user_id) do
    with {:ok, messages} <- Api.Message.get_by_chat_id(chat_id, user_id) do
      {:ok,
       messages
       |> Enum.sort_by(& &1.inserted_at)
       |> Enum.map(&Api.Message.to_public/1)}
    else
      _ -> {:error, "Failed to retrieve conversation history"}
    end
  end

  def new_chat(conn, %{"first_message" => first_message}) do
    chat_params = %{
      "name" => "New Chat",
      "author_id" => conn.assigns[:user_id]
    }

    with {:ok, chat} <- Api.Chat.new(chat_params),
         message_params = %{
           content: first_message,
           role: "user",
           chat_id: chat.id,
           author_id: conn.assigns[:user_id]
         },
         {:ok, message} <- Api.Message.new(message_params) do
      %Api.Workers.RunPipelineJobArgs{
        message: Api.Message.to_public(message),
        api_key: conn.assigns[:api_key],
        is_first_message: true
      }
      |> Api.Workers.RunPipelineJob.new()
      |> Oban.insert()

      conn
      |> put_status(:ok)
      |> json(%{chat: Api.Chat.to_public(chat), message: Api.Message.to_public(message)})
    else
      _ -> conn |> put_status(:internal_server_error) |> json(%{error: "Failed to create chat"})
    end
  end

  def rename_chat(conn, %{"chat_id" => chat_id, "new_name" => new_name}) do
    user_id = conn.assigns[:user_id]

    with {:ok, chat} <- Api.Chat.rename_by_id(chat_id, user_id, new_name) do
      conn |> put_status(:ok) |> json(%{chat: Api.Chat.to_public(chat)})
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "Chat not found or access denied"})
    end
  end

  def delete_chat(conn, %{"chat_id" => chat_id}) do
    user_id = conn.assigns[:user_id]

    with {:ok, _} <- Api.Chat.delete_by_id(chat_id, user_id) do
      conn |> put_status(:no_content) |> json(%{message: "Chat deleted successfully"})
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "Chat not found or access denied"})
    end
  end

  def send_message(conn, %{"chat_id" => chat_id, "content" => content}) do
    message_params = %{
      content: content,
      chat_id: chat_id,
      role: "user",
      author_id: conn.assigns[:user_id]
    }

    with {:ok, message} <- Api.Message.new(message_params) do
      with [] <- Api.Pipeline.ProgressTracker.get_by_chat(chat_id) do
        %Api.Workers.RunPipelineJobArgs{
          message: Api.Message.to_public(message),
          api_key: conn.assigns[:api_key],
          is_first_message: false
        }
        |> Api.Workers.RunPipelineJob.new()
        |> Oban.insert()

        conn
        |> put_status(:ok)
        |> json(Api.Message.to_public(message))
      else
        _ -> conn |> put_status(:too_early) |> json(%{error: "Generation already running"})
      end
    else
      _ -> conn |> put_status(:internal_server_error) |> json(%{error: "Failed to send message"})
    end
  end

  def get_chats(conn, _params) do
    user_id = conn.assigns[:user_id]

    conn
    |> put_status(:ok)
    |> json(
      Api.Chat.get_by_user_id(user_id)
      |> Enum.filter(fn chat -> is_nil(chat.deleted_at) end)
      |> Enum.map(&Api.Chat.to_public/1)
    )
  end

  def get_chat(conn, params) do
    chat_id = params["chat_id"]
    user_id = conn.assigns[:user_id]

    with {:ok, chat} <- Api.Chat.get_by_id(chat_id, user_id) do
      conn
      |> put_status(:ok)
      |> json(Api.Chat.to_public(chat))
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "Chat not found"})
    end
  end

  def get_chat_messages(conn, params) do
    user_id = conn.assigns[:user_id]
    chat_id = params["chat_id"]

    with {:ok, messages} <- get_conversation_history(chat_id, user_id) do
      conn |> put_status(:ok) |> json(messages)
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Messages not found or access denied"})
    end
  end
end
