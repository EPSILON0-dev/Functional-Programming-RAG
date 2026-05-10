defmodule ApiWeb.Sockets.UserSocket do
  use Phoenix.Socket
  channel("user:*", ApiWeb.Channels.UserChannel)

  def connect(params, socket) do
    with token when not is_nil(token) <- params["token"],
         {:ok, user_id} <- ApiWeb.Auth.authenticate_ws_token(token) do
      {:ok, assign(socket, :user_id, user_id)}
    else
      _ -> :error
    end
  end

  def id(socket), do: "user:#{socket.assigns.user_id}"
end
