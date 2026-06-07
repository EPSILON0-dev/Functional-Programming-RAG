defmodule Api.Release do
  @moduledoc """
  Module for running database migrations and other release tasks.
  Used by Docker entrypoint scripts.
  """
  
  @app :api
  
  def migrate do
    load_app()
    
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end
  
  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end
  
  def oban_start do
    load_app()
    # Start Oban and keep the process running
    Application.ensure_all_started(:api)
    
    # Keep the process alive
    Process.sleep(:infinity)
  end
  
  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end
  
  defp load_app do
    Application.load(@app)
  end
end
