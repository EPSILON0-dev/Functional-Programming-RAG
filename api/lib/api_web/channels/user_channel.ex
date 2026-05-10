defmodule ApiWeb.Channels.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _payload, socket) do
    {:ok, assign(socket, :user_id, user_id)}
  end

  def handle_info({:response_complete, message}, socket) do
    push(socket, "response_complete", message)
    {:noreply, socket}
  end
end
