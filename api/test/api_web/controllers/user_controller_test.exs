defmodule ApiWeb.Controllers.UserControllerTest do
  use ApiWeb.ConnCase

  describe "POST /api/auth/register" do
    test "creates user and returns id + username", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/register", %{username: "alice", password: "secret"})
      body = json_response(conn, 200)
      assert body["username"] == "alice"
      assert is_binary(body["id"])
    end

    test "returns 409 for duplicate username", %{conn: conn} do
      insert_user(%{username: "bob"})
      conn = post(conn, ~p"/api/auth/register", %{username: "bob", password: "secret"})
      assert json_response(conn, 409)["error"] =~ "already exists"
    end
  end

  describe "POST /api/auth (login)" do
    test "returns 200 and sets cookie on valid credentials", %{conn: conn} do
      insert_user(%{username: "carol"})
      conn = post(conn, ~p"/api/auth", %{username: "carol", password: "password"})
      assert json_response(conn, 200)["username"] == "carol"
      assert get_resp_header(conn, "set-cookie") != []
    end

    test "returns 401 for wrong password", %{conn: conn} do
      insert_user(%{username: "dan"})
      conn = post(conn, ~p"/api/auth", %{username: "dan", password: "wrong"})
      assert json_response(conn, 401)
    end

    test "returns 404 for unknown username", %{conn: conn} do
      conn = post(conn, ~p"/api/auth", %{username: "ghost", password: "x"})
      assert json_response(conn, 404)
    end
  end

  describe "POST /api/auth/logout" do
    test "returns 200 regardless of auth state", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/logout", %{})
      assert json_response(conn, 200)
    end
  end

  describe "GET /api/auth/me" do
    test "returns user info when authenticated", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> get(~p"/api/auth/me")
      body = json_response(conn, 200)
      assert body["id"] == user.id
      assert body["username"] == user.username
    end

    test "returns 401 without token", %{conn: conn} do
      conn = get(conn, ~p"/api/auth/me")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/auth/wstoken" do
    test "returns a short-lived token when authenticated", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> get(~p"/api/auth/wstoken")
      body = json_response(conn, 200)
      assert is_binary(body["token"])
    end

    test "returns 401 without token", %{conn: conn} do
      conn = get(conn, ~p"/api/auth/wstoken")
      assert json_response(conn, 401)
    end
  end

  describe "PATCH /api/auth/me/username" do
    test "renames user and returns new username", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> patch(~p"/api/auth/me/username", %{username: "new_name"})
      body = json_response(conn, 200)
      assert body["username"] == "new_name"
    end

    test "returns 409 when username is taken", %{conn: conn} do
      insert_user(%{username: "taken"})
      user = insert_user()
      conn = conn |> log_in_conn(user) |> patch(~p"/api/auth/me/username", %{username: "taken"})
      assert json_response(conn, 409)
    end

    test "returns 401 without token", %{conn: conn} do
      conn = patch(conn, ~p"/api/auth/me/username", %{username: "x"})
      assert json_response(conn, 401)
    end
  end

  describe "PATCH /api/auth/me/password" do
    test "changes password with correct old password", %{conn: conn} do
      user = insert_user()

      conn =
        conn
        |> log_in_conn(user)
        |> patch(~p"/api/auth/me/password", %{old_password: "password", new_password: "new123"})

      assert json_response(conn, 200)
    end

    test "returns 401 for wrong old password", %{conn: conn} do
      user = insert_user()

      conn =
        conn
        |> log_in_conn(user)
        |> patch(~p"/api/auth/me/password", %{old_password: "wrong", new_password: "new123"})

      assert json_response(conn, 401)
    end

    test "returns 401 without token", %{conn: conn} do
      conn = patch(conn, ~p"/api/auth/me/password", %{old_password: "x", new_password: "y"})
      assert json_response(conn, 401)
    end
  end

  describe "DELETE /api/auth/me" do
    test "soft-deletes account", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> delete(~p"/api/auth/me")
      assert json_response(conn, 200)

      # subsequent /me should be 401 since user is deleted
      fresh = build_conn() |> log_in_conn(user)
      assert json_response(get(fresh, ~p"/api/auth/me"), 401)
    end

    test "returns 401 without token", %{conn: conn} do
      conn = delete(conn, ~p"/api/auth/me")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/auth/keys" do
    test "returns api keys list", %{conn: conn} do
      user = insert_user()
      insert_api_key(user, %{name: "Key A"})
      conn = conn |> log_in_conn(user) |> get(~p"/api/auth/keys")
      body = json_response(conn, 200)
      assert is_list(body["api_keys"])
      assert Enum.any?(body["api_keys"], &(&1["name"] == "Key A"))
    end

    test "returns empty list when user has no keys", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> get(~p"/api/auth/keys")
      body = json_response(conn, 200)
      assert body["api_keys"] == []
    end

    test "returns 401 without token", %{conn: conn} do
      conn = get(conn, ~p"/api/auth/keys")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/auth/keys" do
    test "creates an api key", %{conn: conn} do
      user = insert_user()
      conn = conn |> log_in_conn(user) |> post(~p"/api/auth/keys", %{name: "New Key", key: "sk-abc"})
      body = json_response(conn, 201)
      assert is_binary(body["id"])
    end

    test "returns 401 without token", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/keys", %{name: "k", key: "v"})
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/auth/keys/selected" do
    test "selects an api key", %{conn: conn} do
      user = insert_user()
      key = insert_api_key(user)
      conn = conn |> log_in_conn(user) |> post(~p"/api/auth/keys/selected", %{key_id: key.id})
      assert json_response(conn, 200)
    end

    test "returns error for another user's key", %{conn: conn} do
      user = insert_user()
      other = insert_user()
      key = insert_api_key(other)
      conn = conn |> log_in_conn(user) |> post(~p"/api/auth/keys/selected", %{key_id: key.id})
      # controller returns 401 when ownership check fails
      assert conn.status in [401, 403, 404]
    end

    test "returns 401 without token", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/keys/selected", %{key_id: Ecto.UUID.generate()})
      assert json_response(conn, 401)
    end
  end

  describe "DELETE /api/auth/keys/:key_id" do
    test "deletes own key", %{conn: conn} do
      user = insert_user()
      key = insert_api_key(user)
      conn = conn |> log_in_conn(user) |> delete(~p"/api/auth/keys/#{key.id}")
      assert conn.status == 204
    end

    test "clears selected_key_id when deleting the selected key", %{conn: conn} do
      user = insert_user()
      key = insert_api_key(user)
      {:ok, _} = Api.User.set_selected_key(user.id, key.id)

      conn |> log_in_conn(user) |> delete(~p"/api/auth/keys/#{key.id}")

      {:ok, updated} = Api.User.get_by_id(user.id)
      assert updated.selected_key_id == nil
    end

    test "returns error for another user's key", %{conn: conn} do
      user = insert_user()
      other = insert_user()
      key = insert_api_key(other)
      conn = conn |> log_in_conn(user) |> delete(~p"/api/auth/keys/#{key.id}")
      assert conn.status in [401, 403, 404]
    end

    test "returns 401 without token", %{conn: conn} do
      conn = delete(conn, ~p"/api/auth/keys/#{Ecto.UUID.generate()}")
      assert json_response(conn, 401)
    end
  end
end
