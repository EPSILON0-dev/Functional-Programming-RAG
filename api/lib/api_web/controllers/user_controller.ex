defmodule ApiWeb.Controllers.UserController do
  use ApiWeb, :controller

  defp hash_password(password) do
    Bcrypt.Base.hash_password(password, Bcrypt.Base.gen_salt(12, true))
  end

  defp gen_user_token(user) do
    ApiWeb.Token.generate_and_sign!(%{
      "user_id" => user.id,
      "ws" => false,
      "exp" => System.os_time(:second) + ApiWeb.Token.max_age()
    })
  end

  defp gen_user_ws_token(user) do
    ApiWeb.Token.generate_and_sign!(%{
      "user_id" => user.id,
      "ws" => true,
      # Short-lived token for WebSocket connections
      "exp" => System.os_time(:second) + 60
    })
  end

  def register(conn, %{"username" => username, "password" => password}) do
    query_params = %{"username" => username, "password" => hash_password(password)}
    query_result = Api.User.new(query_params)

    case query_result do
      {:ok, user} ->
        conn |> put_status(:ok) |> json(%{id: user.id, username: user.username})

      {:error, reason} ->
        if reason.errors[:username] do
          conn |> put_status(:conflict) |> json(%{error: "User already exists"})
        else
          conn |> put_status(:internal_server_error) |> json(%{error: "Failed to create user"})
        end
    end
  end

  def auth(conn, %{"username" => username, "password" => password}) do
    case Api.User.get_by_username(username) do
      {:ok, user} ->
        if user.deleted_at do
          conn |> put_status(:gone) |> json(%{error: "User account has been deleted"})
        else
          if Bcrypt.verify_pass(password, user.password) do
            conn
            |> put_status(:ok)
            |> put_resp_cookie("authorization", "Bearer #{gen_user_token(user)}",
              max_age: ApiWeb.Token.max_age()
            )
            |> json(%{id: user.id, username: user.username})
          else
            conn |> put_status(:unauthorized) |> json(%{error: "Invalid password"})
          end
        end

      {:error, _} ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})
    end
  end

  def logout(conn, _) do
    conn
    |> delete_resp_cookie("authorization")
    |> put_status(:ok)
    |> json(%{message: "Logged out successfully"})
  end

  def me(conn, _) do
    with user_id when not is_nil(user_id) <- conn.assigns[:user_id],
         {:ok, user} <- Api.User.get_by_id(user_id) do
      conn
      |> put_status(:ok)
      |> json(%{id: user.id, username: user.username, selected_key_id: user.selected_key_id})
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end

  def wstoken(conn, _) do
    with user_id when not is_nil(user_id) <- conn.assigns[:user_id],
         {:ok, user} <- Api.User.get_by_id(user_id) do
      token = gen_user_ws_token(user)
      conn |> put_status(:ok) |> json(%{token: token})
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end

  def get_api_keys(conn, _) do
    with user_id when not is_nil(user_id) <- conn.assigns[:user_id],
         {:ok, user} <- Api.User.get_by_id(user_id) do
      api_keys = Api.Repo.preload(user, :api_keys).api_keys
      api_keys = api_keys |> Enum.map(&Api.APIKey.to_public/1)

      conn
      |> put_status(:ok)
      |> json(%{api_keys: api_keys, selected_key_id: user.selected_key_id})
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end

  def add_api_key(conn, %{"name" => name, "key" => key}) do
    encrypted_key = key

    with user_id when not is_nil(user_id) <- conn.assigns[:user_id],
         {:ok, user} <- Api.User.get_by_id(user_id),
         {:ok, api_key} <-
           Api.APIKey.new(%{owner_id: user.id, encrypted_key: encrypted_key, name: name}) do
      conn |> put_status(:created) |> json(%{id: api_key.id})
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end

  def delete_api_key(conn, %{"key_id" => key_id}) do
    with user_id when not is_nil(user_id) <- conn.assigns[:user_id],
         {:ok, _} <- Api.APIKey.delete(key_id, user_id) do
      conn |> put_status(:no_content) |> json(%{message: "API key deleted"})
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end

  def select_api_key(conn, %{"key_id" => key_id}) do
    with user_id when not is_nil(user_id) <- conn.assigns[:user_id],
         {:ok, _} <- Api.APIKey.get_by_id(key_id, user_id),
         {:ok, _} <- Api.User.set_selected_key(user_id, key_id) do
      conn |> put_status(:ok) |> json(%{message: "Selected API key updated"})
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end
end
