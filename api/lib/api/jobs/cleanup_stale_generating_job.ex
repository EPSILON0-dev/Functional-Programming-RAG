defmodule Api.Workers.CleanupStaleGeneratingJob do
  @moduledoc """
  Periodic Oban job that finds messages stuck in `role: "generating"` for longer
  than `@max_age_minutes` and marks them as `role: "error"`.

  This covers the case where the BEAM crashed mid-pipeline and the ProgressTracker
  ETS table was wiped, leaving orphaned generating messages in the database.

  Scheduled every 5 minutes via Oban.Plugins.Cron.
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  import Ecto.Query

  @max_age_minutes 10
  @timeout_content "Response generation timed out."

  @impl Oban.Worker
  def perform(_job) do
    cutoff =
      DateTime.utc_now()
      |> DateTime.add(-@max_age_minutes * 60, :second)
      |> DateTime.truncate(:second)

    stale =
      from(m in Api.Message,
        where:
          m.role == "generating" and
            m.inserted_at < ^cutoff and
            is_nil(m.deleted_at)
      )
      |> Api.Repo.all()

    Enum.each(stale, fn message ->
      Api.Message.update_by_id(message.id, %{
        content: @timeout_content,
        role: "error",
        metadata: %{"error" => "timed_out"}
      })

      # No-op if the job already finished and removed itself, but safe to call.
      Api.Pipeline.ProgressTracker.complete_job(message.id)
    end)

    {:ok, "Cleaned #{length(stale)} stale generating message(s)"}
  end
end
