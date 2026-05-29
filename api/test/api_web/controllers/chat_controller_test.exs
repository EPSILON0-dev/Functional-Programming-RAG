defmodule ApiWeb.Controllers.ChatControllerTest do
  use ApiWeb.ConnCase

  describe "GET /api/chats" do
    test "returns only own non-deleted chats", %{conn: conn} do
      user = insert_user()
      other = insert_user()
      chat = insert_chat(user, %{name: "Mine"})
      _other_chat = insert_chat(other, %{name: "Not mine"})

      conn = conn |> log_in_conn(user) |> get(~p"/api/chats")
      body = json_response(conn, 200)
      ids = Enum.map(body, & &1["id"])
      assert chat.id in ids
      refute Enum.any?(body, &(&1["name"] == "Not mine"))
    end

    test "returns empty list when user has no chats", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> get(~p"/api/chats")
      assert json_response(conn, 200) == []
    end

    test "excludes soft-deleted chats", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      Api.Chat.delete_by_id(chat.id, user.id)

      conn = conn |> log_in_conn(user) |> get(~p"/api/chats")
      body = json_response(conn, 200)
      ids = Enum.map(body, & &1["id"])
      refute chat.id in ids
    end

    test "returns 401 without token", %{conn: conn} do
      conn = get(conn, ~p"/api/chats")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/chats/:chat_id" do
    test "returns own chat", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user, %{name: "My Chat"})
      conn = conn |> log_in_conn(user) |> get(~p"/api/chats/#{chat.id}")
      body = json_response(conn, 200)
      assert body["id"] == chat.id
      assert body["name"] == "My Chat"
    end

    test "returns 404 for another user's chat", %{conn: conn} do
      owner = insert_user()
      other = insert_user()
      chat = insert_chat(owner)
      conn = conn |> log_in_conn(other) |> get(~p"/api/chats/#{chat.id}")
      assert json_response(conn, 404)
    end

    test "returns 404 for soft-deleted chat", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      Api.Chat.delete_by_id(chat.id, user.id)
      conn = conn |> log_in_conn(user) |> get(~p"/api/chats/#{chat.id}")
      assert json_response(conn, 404)
    end

    test "returns 404 for unknown id", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> get(~p"/api/chats/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end

    test "returns 401 without token", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      conn = get(conn, ~p"/api/chats/#{chat.id}")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/chats/:chat_id/messages" do
    test "returns messages for own chat", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      msg = insert_message(chat, user, %{content: "Hello"})

      conn = conn |> log_in_conn(user) |> get(~p"/api/chats/#{chat.id}/messages")
      body = json_response(conn, 200)
      ids = Enum.map(body, & &1["id"])
      assert msg.id in ids
    end

    test "returns empty list for chat with no messages", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      conn = conn |> log_in_conn(user) |> get(~p"/api/chats/#{chat.id}/messages")
      assert json_response(conn, 200) == []
    end

    test "returns 404 for another user's chat", %{conn: conn} do
      owner = insert_user()
      other = insert_user()
      chat = insert_chat(owner)

      conn = conn |> log_in_conn(other) |> get(~p"/api/chats/#{chat.id}/messages")
      assert json_response(conn, 404)
    end

    test "returns 401 without token", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      conn = get(conn, ~p"/api/chats/#{chat.id}/messages")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/chats/new" do
    test "creates chat + message, enqueues response job", %{conn: conn} do
      user = insert_user()
      key = insert_api_key(user)

      conn =
        conn
        |> log_in_with_key(user, key)
        |> post(~p"/api/chats/new", %{first_message: "Hello"})

      body = json_response(conn, 200)
      assert is_map(body["chat"])
      assert is_map(body["message"])
      assert body["chat"]["author_id"] == user.id
      assert body["message"]["content"] == "Hello"
      assert_enqueued(worker: Api.Workers.GenerateResponseJob)
    end

    test "returns 403 without a selected api key", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> post(~p"/api/chats/new", %{first_message: "Hello"})
      assert json_response(conn, 403)
    end

    test "returns 401 without token", %{conn: conn} do
      conn = post(conn, ~p"/api/chats/new", %{first_message: "Hello"})
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/chats/:chat_id/messages" do
    test "creates message and enqueues response job", %{conn: conn} do
      user = insert_user()
      key = insert_api_key(user)
      chat = insert_chat(user)

      conn =
        conn
        |> log_in_with_key(user, key)
        |> post(~p"/api/chats/#{chat.id}/messages", %{content: "Follow-up"})

      body = json_response(conn, 200)
      assert body["content"] == "Follow-up"
      assert body["role"] == "user"
      assert_enqueued(worker: Api.Workers.GenerateResponseJob)
    end

    test "allows sending a message to any existing chat (no ownership check)", %{conn: conn} do
      owner = insert_user()
      other = insert_user()
      key = insert_api_key(other)
      chat = insert_chat(owner)

      conn =
        conn
        |> log_in_with_key(other, key)
        |> post(~p"/api/chats/#{chat.id}/messages", %{content: "Hack"})

      # No ownership check in send_message — the message is created successfully
      assert json_response(conn, 200)
    end

    test "returns 403 without a selected api key", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      conn = conn |> log_in_conn(user) |> post(~p"/api/chats/#{chat.id}/messages", %{content: "x"})
      assert json_response(conn, 403)
    end

    test "returns 401 without token", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      conn = post(conn, ~p"/api/chats/#{chat.id}/messages", %{content: "x"})
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/chats/:chat_id/rename" do
    test "renames own chat", %{conn: conn} do
      user = insert_user()
      key = insert_api_key(user)
      chat = insert_chat(user)

      conn =
        conn
        |> log_in_with_key(user, key)
        |> post(~p"/api/chats/#{chat.id}/rename", %{new_name: "Renamed"})

      body = json_response(conn, 200)
      assert body["chat"]["name"] == "Renamed"
    end

    test "returns 404 for another user's chat", %{conn: conn} do
      owner = insert_user()
      other = insert_user()
      key = insert_api_key(other)
      chat = insert_chat(owner)

      conn =
        conn
        |> log_in_with_key(other, key)
        |> post(~p"/api/chats/#{chat.id}/rename", %{new_name: "Hack"})

      assert json_response(conn, 404)
    end

    test "returns 403 without a selected api key", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)

      conn =
        conn
        |> log_in_conn(user)
        |> post(~p"/api/chats/#{chat.id}/rename", %{new_name: "X"})

      assert json_response(conn, 403)
    end

    test "returns 401 without token", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      conn = post(conn, ~p"/api/chats/#{chat.id}/rename", %{new_name: "X"})
      assert json_response(conn, 401)
    end
  end

  describe "DELETE /api/chats/:chat_id" do
    test "soft-deletes own chat", %{conn: conn} do
      user = insert_user()
      key = insert_api_key(user)
      chat = insert_chat(user)

      conn = conn |> log_in_with_key(user, key) |> delete(~p"/api/chats/#{chat.id}")
      assert conn.status == 204

      # Chat is no longer retrievable
      fresh = build_conn() |> log_in_conn(user)
      assert json_response(get(fresh, ~p"/api/chats/#{chat.id}"), 404)
    end

    test "returns 404 for another user's chat", %{conn: conn} do
      owner = insert_user()
      other = insert_user()
      key = insert_api_key(other)
      chat = insert_chat(owner)

      conn = conn |> log_in_with_key(other, key) |> delete(~p"/api/chats/#{chat.id}")
      assert json_response(conn, 404)
    end

    test "returns 403 without a selected api key", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      conn = conn |> log_in_conn(user) |> delete(~p"/api/chats/#{chat.id}")
      assert json_response(conn, 403)
    end

    test "returns 401 without token", %{conn: conn} do
      user = insert_user()
      chat = insert_chat(user)
      conn = delete(conn, ~p"/api/chats/#{chat.id}")
      assert json_response(conn, 401)
    end
  end
end
