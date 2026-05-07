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
    :ok
  end
end
