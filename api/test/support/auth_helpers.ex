defmodule ApiWeb.AuthHelpers do
  @moduledoc """
  Helpers for authenticating connections in controller tests.
  """

  def log_in_conn(conn, user) do
    token =
      ApiWeb.Token.generate_and_sign!(%{
        "user_id" => user.id,
        "ws" => false,
        "exp" => System.os_time(:second) + ApiWeb.Token.max_age()
      })

    Plug.Test.put_req_cookie(conn, "authorization", "Bearer #{token}")
  end

  def log_in_with_key(conn, user, key) do
    {:ok, _} = Api.User.set_selected_key(user.id, key.id)
    log_in_conn(conn, user)
  end
end
