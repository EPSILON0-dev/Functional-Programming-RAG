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
      "name" => String.slice(first_message, 0..20),
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
      %{
        message: Api.Message.to_public(message),
        api_key: conn.assigns[:api_key]
      }
      |> Api.Workers.GenerateResponseJob.new()
      |> Oban.insert()

      conn
      |> put_status(:ok)
      |> json(%{chat: Api.Chat.to_public(chat), message: Api.Message.to_public(message)})
    else
      _ -> conn |> put_status(:internal_server_error) |> json(%{error: "Failed to create chat"})
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
      %{
        message: Api.Message.to_public(message),
        api_key: conn.assigns[:api_key]
      }
      |> Api.Workers.GenerateResponseJob.new()
      |> Oban.insert()

      conn
      |> put_status(:ok)
      |> json(Api.Message.to_public(message))
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
