import Config

config :api, Api.Repo,
  username: System.get_env("DB_USERNAME", "pf_rag_dev_user"),
  password: System.get_env("DB_PASSWORD", "pf_rag_dev_password"),
  hostname: System.get_env("DB_HOST", "localhost"),
  database: System.get_env("DB_NAME", "pf_rag_db"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10"))

config :api, ApiWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))],
  ws: [ip: {0, 0, 0, 0}],
  check_origin: false,
  code_reloader: false,
  debug_errors: false,
  secret_key_base: System.get_env("SECRET_KEY_BASE", "o1dCqY41BFd5wQ6t7dzaB8bT40JzJSxW2M0SbA+yf0Pb1yydUsfNdVj+Uz+nwma8"),
  server: true

config :logger, level: :warning
config :joken, default_signer: System.get_env("JOKEN_SIGNER", "super_secret_key_for_dev_only_change_in_prod")

config :api, Api.Pipeline, debug: false
