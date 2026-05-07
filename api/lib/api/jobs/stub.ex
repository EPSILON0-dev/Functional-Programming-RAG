defmodule Api.Workers.StubJob do
  use Oban.Worker,
    queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    IO.puts("StubJob started with args: #{inspect(args)}")
    :timer.sleep(2000)
    IO.puts("StubJob 50% complete")
    :timer.sleep(2000)
    IO.puts("StubJob completed")

    message_params = %{
      "content" => "This is a stub response to the message: \"#{args["content"]}\"",
      "role" => "assistant",
      "chat_id" => args["chat_id"],
      "author_id" => nil
    }

    with {:ok, _message} <- Api.Message.new_message(message_params) do
      :ok
    else
      :error -> :error
    end
  end
end
