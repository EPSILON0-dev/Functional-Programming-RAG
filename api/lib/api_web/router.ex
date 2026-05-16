defmodule ApiWeb.Router do
  use ApiWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :auth_api do
    plug(:accepts, ["json"])
    plug(ApiWeb.Auth, :authenticate_conn)
  end

  pipeline :auth_with_api_key do
    plug(:accepts, ["json"])
    plug(ApiWeb.Auth, :authenticate_conn)
    plug(ApiWeb.Auth, :verify_api_key)
  end

  scope "/api/auth", ApiWeb do
    pipe_through(:auth_api)

    get("/me", Controllers.UserController, :me)
    get("/wstoken", Controllers.UserController, :wstoken)

    get("/keys", Controllers.UserController, :get_api_keys)
    post("/keys", Controllers.UserController, :add_api_key)
    post("/keys/selected", Controllers.UserController, :select_api_key)
    delete("/keys/:key_id", Controllers.UserController, :delete_api_key)
  end

  scope "/api/auth", ApiWeb do
    pipe_through(:api)

    post("/", Controllers.UserController, :auth)
    post("/register", Controllers.UserController, :register)
    post("/logout", Controllers.UserController, :logout)
  end

  scope "/api/chats", ApiWeb do
    pipe_through(:auth_api)

    get("/", Controllers.ChatController, :get_chats)
    get("/:chat_id", Controllers.ChatController, :get_chat)
    get("/:chat_id/messages", Controllers.ChatController, :get_chat_messages)
  end

  scope "/api/chats", ApiWeb do
    pipe_through([:auth_with_api_key])

    post("/new", Controllers.ChatController, :new_chat)
    post("/:chat_id/messages", Controllers.ChatController, :send_message)
    post("/:chat_id/rename", Controllers.ChatController, :rename_chat)
    delete("/:chat_id", Controllers.ChatController, :delete_chat)
  end

  if Application.compile_env(:api, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:fetch_session, :protect_from_forgery])

      live_dashboard("/dashboard", metrics: ApiWeb.Telemetry)
    end
  end
end
