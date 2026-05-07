defmodule ApiWeb.Controllers.UserController do
  use ApiWeb, :controller

  defp hash_password(password) do
    Bcrypt.Base.hash_password(password, Bcrypt.Base.gen_salt(12, true))
  end

  defp gen_user_token(user) do
    ApiWeb.Token.generate_and_sign!(%{
      "user_id" => user.id
    })
  end

  def register(conn, %{"username" => username, "password" => password}) do
    query_params = %{"username" => username, "password" => hash_password(password)}
    query_result = Api.User.create_user(query_params)

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
    case Api.User.get_user_by_username(username) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})

      user ->
        if user.deleted_at do
          conn |> put_status(:gone) |> json(%{error: "User account has been deleted"})
        else
          if Bcrypt.verify_pass(password, user.password) do
            conn
            |> put_status(:ok)
            |> put_resp_cookie("authorization", "Bearer #{gen_user_token(user)}", max_age: 600)
            |> json(%{id: user.id, username: user.username})
          else
            conn |> put_status(:unauthorized) |> json(%{error: "Invalid password"})
          end
        end
    end
  end

  def logout(conn, _) do
    conn
    |> delete_resp_cookie("authorization")
    |> put_status(:ok)
    |> json(%{message: "Logged out successfully"})
  end

  def me(conn, _) do
    with user when not is_nil(user) <- Api.User.get_user_by_id(conn.assigns[:user_id]) do
      conn |> put_status(:ok) |> json(%{id: user.id, username: user.username})
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
    end
  end
end
