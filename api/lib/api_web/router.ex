defmodule ApiWeb.Router do
  use ApiWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :auth_api do
    plug(:accepts, ["json"])
    plug(ApiWeb.Auth, :authenticate_conn)
  end

  scope "/api/auth", ApiWeb do
    pipe_through(:auth_api)

    get("/me", Controllers.UserController, :me)
    get("/wstoken", Controllers.UserController, :wstoken)
  end

  scope "/api/auth", ApiWeb do
    pipe_through(:api)

    post("/", Controllers.UserController, :auth)
    post("/register", Controllers.UserController, :register)
    post("/logout", Controllers.UserController, :logout)
  end

  scope "/api/chats", ApiWeb do
    pipe_through(:auth_api)

    post("/new", Controllers.ChatController, :new_chat)
    get("/", Controllers.ChatController, :get_chats)
    get("/:chat_id", Controllers.ChatController, :get_chat)
    get("/:chat_id/messages", Controllers.ChatController, :get_chat_messages)
    post("/:chat_id/messages", Controllers.ChatController, :send_message)
  end

  if Application.compile_env(:api, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:fetch_session, :protect_from_forgery])

      live_dashboard("/dashboard", metrics: ApiWeb.Telemetry)
    end
  end
end
