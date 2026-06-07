defmodule ApiWeb.Controllers.HealthController do
  use ApiWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok", timestamp: DateTime.utc_now() |> DateTime.to_iso8601()})
  end
end
