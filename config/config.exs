# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :band_web,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :band_web, BandWebWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BandWebWeb.ErrorHTML, json: BandWebWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: BandWeb.PubSub,
  live_view: [signing_salt: "mfl+pFkf"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :band_web, BandWeb.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11"

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  band_web: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/band_web/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Band API 설정 (서버 측 프록시용)
config :band_web,
  # 개발자 센터에서 미리 발급받은 토큰 사용
  band_access_token: System.get_env("BAND_ACCESS_TOKEN"),
  # 또는 OAuth 플로우용 앱 정보
  band_app_client_id: System.get_env("BAND_CLIENT_ID"),
  band_app_client_secret: System.get_env("BAND_CLIENT_SECRET")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#
