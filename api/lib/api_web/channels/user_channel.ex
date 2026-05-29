defmodule ApiWeb.Channels.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _payload, socket) do
    if socket.assigns[:user_id] == user_id do
      # Defer sync so the join reply is sent before we push progress events
      send(self(), {:after_join, user_id})
      {:ok, assign(socket, :user_id, user_id)}
    else
      {:error, %{reason: "Unauthorized"}}
    end
  end

  # Late-joiner sync: push the current pipeline stage for every active job
  # belonging to this user so they don't need to poll.
  def handle_info({:after_join, user_id}, socket) do
    Api.Pipeline.ProgressTracker.get_by_user(user_id)
    |> Enum.each(fn progress -> push(socket, "pipeline_progress", progress) end)

    {:noreply, socket}
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
