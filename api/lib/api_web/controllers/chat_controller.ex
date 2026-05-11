defmodule ApiWeb.Controllers.ChatController do
  use ApiWeb, :controller

  defp message_convert(message) do
    %{
      id: message.id,
      content: message.content,
      role: message.role,
      chat_id: message.chat_id,
      author_id: message.author_id,
      timestamp: message.inserted_at
    }
  end

  def new_chat(conn, %{"first_message" => first_message}) do
    chat_params = %{"name" => "New Chat", "author_id" => conn.assigns[:user_id]}

    with {:ok, chat} <- Api.Chat.new_chat(chat_params),
         message_params = %{
           content: first_message,
           role: "user",
           chat_id: chat.id,
           author_id: conn.assigns[:user_id]
         },
         {:ok, message} <- Api.Message.new_message(message_params) do
      message_convert(message)
      |> Api.Workers.GenerateResponseJob.new()
      |> Oban.insert()

      conn
      |> put_status(:ok)
      |> json(%{chat: %{id: chat.id, name: chat.name}, message: message_convert(message)})
    else
      _ -> conn |> put_status(:internal_server_error) |> json(%{error: "Failed to create chat"})
    end
  end

  def send_message(conn, %{"chat_id" => chat_id, "content" => content}) do
    message_params = %{
      content: content,
      role: "user",
      chat_id: chat_id,
      author_id: conn.assigns[:user_id]
    }

    with {:ok, message} <- Api.Message.new_message(message_params) do
      message_convert(message)
      |> Api.Workers.GenerateResponseJob.new()
      |> Oban.insert()

      conn
      |> put_status(:ok)
      |> json(%{
        id: message.id,
        content: message.content,
        role: message.role,
        timestamp: message.inserted_at
      })
    else
      _ -> conn |> put_status(:internal_server_error) |> json(%{error: "Failed to send message"})
    end
  end

  def get_chats(conn, _params) do
    user_id = conn.assigns[:user_id]
    chats = Api.Chat.get_user_chats(user_id)
    conn |> put_status(:ok) |> json(chats)
  end

  def get_chat(conn, params) do
    chat_id = params["chat_id"]
    user_id = conn.assigns[:user_id]

    db_chat = Api.Chat.get_chat_by_id(user_id, chat_id)

    chat = %{
      id: db_chat.id,
      name: db_chat.name,
      author_id: db_chat.author_id,
      timestamp: db_chat.inserted_at
    }

    conn |> put_status(:ok) |> json(chat)
  end

  def get_chat_messages(conn, params) do
    limit = params["limit"] || 20
    offset = params["offset"] || 0
    chat_id = params["chat_id"]

    messages =
      Api.Message.get_chat_messages(chat_id)
      |> Enum.map(
        &%{
          id: &1.id,
          content: &1.content,
          role: &1.role,
          provider_metadata: &1.provider_metadata,
          usage_metadata: &1.usage_metadata,
          timestamp: &1.inserted_at
        }
      )

    conn |> put_status(:ok) |> json(messages)
  end
end
