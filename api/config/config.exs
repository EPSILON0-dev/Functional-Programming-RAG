# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :api,
  ecto_repos: [Api.Repo],
  generators: [timestamp_type: :utc_datetime]

config :api, Api.Repo, types: Api.PostgrexTypes

# Configure the endpoint
config :api, ApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Api.PubSub,
  live_view: [signing_salt: "JUgVqoT3"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Oban configuration
config :api, Oban,
  repo: Api.Repo,
  queues: [
    default: 10
  ]

# Configuration for the document loader
config :api, Api.Loader,
  llm_model: "openai/gpt-4.1-nano",
  embedding_model: "openai/text-embedding-3-small",
  chunk_size: 4000,
  overlap_size: 750,
  minimal_relevance: 0.5,
  processing_concurrency: 32,
  job_timeout_seconds: 120,
  debug: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
