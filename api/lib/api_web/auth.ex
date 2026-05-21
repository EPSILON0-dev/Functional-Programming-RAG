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

  def verify_api_key(conn, _opts) do
    user_id = conn.assigns[:user_id]

    with user <- Api.Repo.get_by(Api.User, id: user_id),
         api_key <-
           user
           |> Api.Repo.preload(:api_keys)
           |> Map.get(:api_keys)
           |> Enum.find(&(&1.id == user.selected_key_id)),
         false <- is_nil(api_key),
         encrypted_key when not is_nil(encrypted_key) <- api_key.encrypted_key,
         final_key when not is_nil(final_key) <- Api.APIKey.decrypt_key(encrypted_key) do
      conn |> assign(:api_key, final_key)
    else
      _ -> conn |> put_status(:forbidden) |> json(%{error: "API key required"}) |> halt()
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
