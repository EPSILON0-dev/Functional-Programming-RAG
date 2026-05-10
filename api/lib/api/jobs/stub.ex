defmodule Api.Workers.StubJob do
  use Oban.Worker,
    queue: :default,
    max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    IO.puts("StubJob started with args: #{inspect(args)}")
    :timer.sleep(200)
    IO.puts("StubJob 50% complete")
    :timer.sleep(200)
    IO.puts("StubJob completed")

    message_params = %{
      "content" => "This is a stub response to the message: \"#{args["content"]}\"",
      "role" => "assistant",
      "chat_id" => args["chat_id"],
      "author_id" => nil
    }

    with {:ok, message} <- Api.Message.new_message(message_params) do
      Phoenix.PubSub.broadcast(
        Api.PubSub,
        "user:#{args["author_id"]}",
        {:response_complete,
         %{id: message.id, chat_id: message.chat_id, content: message.content}}
      )

      :ok
    else
      _ -> :error
    end
  end
end
