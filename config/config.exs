# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :rujira,
  ecto_repos: [Rujira.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :rujira, RujiraWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: RujiraWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Rujira.PubSub,
  live_view: [signing_salt: "SjwK2jgU"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :cors_plug,
  origin: [
    "http://localhost:5173",
    ~r/https:\/\/rujira-ui-main\.vercel\.app/,
    ~r/https:\/\/rujira-ui-main-git-[a-z]+-rujira\.vercel\.app/,
    "https://rujira.network"
  ],
  max_age: 86400,
  methods: ["GET", "POST"]

config :tesla, :adapter, {Tesla.Adapter.Finch, name: Rujira.Finch}

config :memoize, cache_strategy: Rujira.CacheStrategy

target = System.get_env("TARGET") || "dev"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{target}.exs"

config :appsignal, :config,
  otp_app: :appsignal_phoenix_example,
  name: "rujira",
  push_api_key: "96acf591-1717-4e1d-aa2c-769453fed4b9",
  env: Mix.env,
  active: true
