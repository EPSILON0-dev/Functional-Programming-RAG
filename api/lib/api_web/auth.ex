defmodule ApiWeb.Auth do
  use ApiWeb, :controller

  def authenticate_conn(conn, _opts) do
    cookie = conn.req_cookies["authorization"]

    with ["Bearer", token] <- String.split(cookie || "", " "),
         {:ok, claims} <- ApiWeb.Token.verify_and_validate(token),
         false <- claims["ws"],
         user_id = claims["user_id"] do
      conn |> assign(:user_id, user_id)
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"}) |> halt()
    end
  end

  def authenticate_ws_token(token) do
    with {:ok, claims} <- ApiWeb.Token.verify_and_validate(token),
         true <- claims["ws"],
         user_id = claims["user_id"] do
      {:ok, user_id}
    else
      _ -> {:error, :unauthorized}
    end
  end
end
