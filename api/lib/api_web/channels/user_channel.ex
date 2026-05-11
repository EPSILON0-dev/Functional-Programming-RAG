defmodule ApiWeb.Channels.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _payload, socket) do
    if socket.assigns[:user_id] == user_id do
      {:ok, assign(socket, :user_id, user_id)}
    else
      {:error, %{reason: "Unauthorized"}}
    end
  end

  def handle_info({:response_new, message}, socket) do
    push(socket, "response_new", message)
    {:noreply, socket}
  end

  def handle_info({:response_complete, message}, socket) do
    push(socket, "response_complete", message)
    {:noreply, socket}
  end
end
