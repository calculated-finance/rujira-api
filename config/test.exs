import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :rujira, Rujira.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  database: "rujira_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  observers: []

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :rujira, RujiraWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "HRNp7vjHuyVOEOVRMDbPDyMe5dv9P1Bw24h6pmUodSB06Pe1HnqwchWbATuT03UJ",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :appsignal, :config,
  active: true,
  env: :test

# Test against stagenet
config :rujira, Thornode,
  subscriptions: ["tm.event='NewBlock'"],
  size: 5,
  grpcs: ["stagenet-grpc.ninerealms.com:443"]

config :rujira, :network, "stagenet"

config :rujira, :accounts,
  # mnemonic: "dog dog dog dog dog dog dog dog dog dog dog dog dog dog dog dog dog dog dog dog dog dog dog fossil"
  empty_account: "sthor1zf3gsk7edzwl9syyefvfhle37cjtql3585mpmq",
  # mnemonic: "cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat cat crawl"
  populated_account: "sthor1uuds8pd92qnnq0udw0rpg0szpgcslc9ph3j6kf"

config :tesla, adapter: Tesla.Mock
