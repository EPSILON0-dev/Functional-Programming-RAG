defmodule ApiWeb.Controllers.UserController do
  use ApiWeb, :controller

  defp hash_password(password) do
    Bcrypt.Base.hash_password(password, Bcrypt.Base.gen_salt(12, true))
  end

  defp return_bad_request(conn) do
    conn |> put_status(:bad_request) |> json(%{error: "Invalid parameters"})
  end

  defp gen_user_token(user) do
    # TODO Move to a parameter
    ApiWeb.Token.generate_and_sign!(%{
      "user_id" => user.id,
      "timestamp" => DateTime.utc_now() |> DateTime.to_unix()
    })
  end

  def register(conn, %{"username" => username, "password" => password} = params) do
    query_params = %{"username" => username, "password" => hash_password(password)}
    query_result = Api.Users.create_user(query_params)

    case query_result do
      {:ok, user} ->
        conn |> put_status(:ok) |> json(%{id: user.id, username: user.username})

      {:error, reason} ->
        if reason.errors[:username] do
          conn |> put_status(:conflict) |> json(%{error: "Username already exists"})
        else
          conn |> put_status(:internal_server_error) |> json(%{error: "Failed to create user"})
        end
    end
  end

  def register(conn, _params) do
    conn |> return_bad_request()
  end

  def login(conn, %{"username" => username, "password" => password} = params) do
    query_params = %{"username" => username}
    query_result = Api.Users.get_user(query_params)

    case query_result do
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

  def login(conn, _params) do
    conn |> return_bad_request()
  end
end
