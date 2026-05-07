defmodule ApiWeb.Router do
  use ApiWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :auth_api do
    plug(:accepts, ["json"])
    plug(ApiWeb.Auth, :authenticate_user)
  end

  scope "/api/users", ApiWeb do
    pipe_through(:api)

    post("/register", Controllers.UserController, :register)
    post("/auth", Controllers.UserController, :auth)
    post("/logout", Controllers.UserController, :logout)
  end

  scope "/api/users", ApiWeb do
    pipe_through(:auth_api)

    get("/me", Controllers.UserController, :me)
  end

  scope "/api/chats", ApiWeb do
    pipe_through(:auth_api)

    post("/new", Controllers.ChatController, :new_chat)
    get("/", Controllers.ChatController, :get_chats)
    get("/:chat_id", Controllers.ChatController, :get_chat)
    get("/:chat_id/messages", Controllers.ChatController, :get_chat_messages)
  end

  if Application.compile_env(:api, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:fetch_session, :protect_from_forgery])

      live_dashboard("/dashboard", metrics: ApiWeb.Telemetry)
    end
  end
end
