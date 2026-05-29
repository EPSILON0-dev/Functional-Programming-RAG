defmodule Api.Workers.GenerateTitleJob do
  use Oban.Worker,
    queue: :default,
    max_attempts: 1

  alias Api.Pipeline.TitleGeneration

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    with {:ok, response} <-
           TitleGeneration.generate_title(args["api_key"], args["chat_id"], args["user_id"]) do
      TitleGeneration.handle_rename(args["chat_id"], args["user_id"], response.content)
    else
      {_, reason} ->
        {:error, reason}
    end
  end
end
