import Config

config :api, Api.Repo,
  username: System.get_env("DB_USERNAME", "pf_rag_dev_user"),
  password: System.get_env("DB_PASSWORD", "pf_rag_dev_password"),
  hostname: System.get_env("DB_HOST", "localhost"),
  database: System.get_env("DB_NAME", "pf_rag_db"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :api, ApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}],
  ws: [ip: {127, 0, 0, 1}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "o1dCqY41BFd5wQ6t7dzaB8bT40JzJSxW2M0SbA+yf0Pb1yydUsfNdVj+Uz+nwma8",
  watchers: []

config :api, dev_routes: true

config :logger, :default_formatter, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
config :joken, default_signer: "super_secret_key_for_dev_only_change_in_prod"

config :api, Api.Pipeline, debug: true
