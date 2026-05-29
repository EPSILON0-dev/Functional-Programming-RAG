defmodule Api.Pipeline.Debug do
  @moduledoc """
  Lightweight debug-logging helper for pipeline stages.

  Enable via config:
    config :api, Api.Pipeline, debug: true

  Each stage calls `Api.Pipeline.Debug.log/2` with a label and the value to
  inspect. When debug is disabled this is a no-op; when enabled it prints to
  stdout with full depth (no truncation).
  """

  @doc "Logs `value` if pipeline debug is enabled, then returns `value` unchanged."
  def log(label, value) do
    if Application.get_env(:api, Api.Pipeline)[:debug] || false do
      IO.inspect(value,
        label: "[Pipeline:#{label}]",
        limit: :infinity,
        printable_limit: :infinity
      )
    end

    value
  end
end
