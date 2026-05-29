defmodule Api.Pipeline.ProgressTracker do
  @moduledoc """
  Tracks in-flight pipeline jobs using an ETS table owned by this GenServer.

  Each entry stores the current stage and accumulated cost for one running job.
  All reads and writes go directly to ETS (no GenServer bottleneck) — the GenServer
  only exists to own and initialise the table.

  State is ephemeral: if the BEAM restarts the table is empty, and stale
  `role: "generating"` DB messages are cleaned up by `CleanupStaleGeneratingJob`.
  """

  use GenServer

  @table :pipeline_progress
  @total_stages 6

  # ---------------------------------------------------------------------------
  # Public API — all direct ETS calls, no GenServer roundtrip
  # ---------------------------------------------------------------------------

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc "Register a new pipeline job. Call immediately after creating the generating message."
  def start_job(message_id, chat_id, user_id) do
    now = DateTime.utc_now()
    :ets.insert(@table, {message_id, 0, "starting", chat_id, user_id, now, now, 0.0})
    :ok
  end

  @doc "Advance to the next stage and update the accumulated cost."
  def update_stage(message_id, stage, stage_name, accumulated_cost) do
    case :ets.lookup(@table, message_id) do
      [{_, _, _, chat_id, user_id, job_started_at, _, _}] ->
        :ets.insert(
          @table,
          {message_id, stage, stage_name, chat_id, user_id, job_started_at, DateTime.utc_now(),
           accumulated_cost}
        )

      [] ->
        :ok
    end

    :ok
  end

  @doc "Remove a completed (or errored) job from the tracker."
  def complete_job(message_id) do
    :ets.delete(@table, message_id)
    :ok
  end

  @doc "Return all active jobs for a given user as progress payloads."
  def get_by_user(user_id) do
    :ets.tab2list(@table)
    |> Enum.filter(fn {_, _, _, _, uid, _, _, _} -> uid == user_id end)
    |> Enum.map(&to_progress_map/1)
  end

  @doc "Return the current progress payload for a single job, or {:error, :not_found}."
  def to_progress_event(message_id) do
    case :ets.lookup(@table, message_id) do
      [row] -> {:ok, to_progress_map(row)}
      [] -> {:error, :not_found}
    end
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{}}
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp to_progress_map(
         {message_id, stage, stage_name, chat_id, _user_id, job_started_at, stage_started_at,
          accumulated_cost}
       ) do
    %{
      message_id: message_id,
      chat_id: chat_id,
      stage: stage,
      stage_name: stage_name,
      total_stages: @total_stages,
      accumulated_cost: accumulated_cost,
      elapsed_ms: DateTime.diff(DateTime.utc_now(), job_started_at, :millisecond),
      stage_started_at: DateTime.to_iso8601(stage_started_at)
    }
  end
end
