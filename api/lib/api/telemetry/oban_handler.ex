defmodule Api.Telemetry.ObanHandler do
  @moduledoc """
  Telemetry handler for Oban job errors.
  """

  def handle_job_error(_event, _measurements, metadata, _config) do
    IO.puts("""
    OBAN JOB CRASH

    Worker: #{inspect(metadata.worker)}
    Queue: #{inspect(metadata.queue)}
    Error: #{inspect(metadata.reason)}
    Stacktrace:
    #{Exception.format_stacktrace(metadata.stacktrace)}
    """)
  end
end
