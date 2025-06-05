# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.

# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :band_api,
  ecto_repos: [BandApi.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :band_api, BandApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: BandApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: BandApi.PubSub,
  live_view: [signing_salt: "T+1UPmhn"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :band_api, BandApi.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Band Core 라이브러리 설정 (웹 서버 제거됨)
config :band_core,
  # OAuth 플로우용 앱 정보
  band_app_client_id: System.get_env("BAND_CLIENT_ID"),
  band_app_client_secret: System.get_env("BAND_CLIENT_SECRET")

# CORS 설정
config :band_api,
  :cors_origins, [
  "http://localhost:3000",
  "http://localhost:4000"
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
