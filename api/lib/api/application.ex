defmodule Api.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ApiWeb.Telemetry,
      Api.Repo,
      {DNSCluster, query: Application.get_env(:api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Api.PubSub},
      {Oban, Application.fetch_env!(:api, Oban)},
      # Start a worker by calling: Api.Worker.start_link(arg)
      # {Api.Worker, arg},
      # Start to serve requests, typically the last entry
      ApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Api.Supervisor]
    {:ok, _} = result = Supervisor.start_link(children, opts)

    :telemetry.attach(
      "oban-job-errors",
      [:oban, :job, :exception],
      &handle_oban_job_error/4,
      nil
    )

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp handle_oban_job_error(_event, _measurements, metadata, _config) do
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
