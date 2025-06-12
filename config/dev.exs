import Config

# Enable dev routes for dashboard and mailbox
config :rujira,
  dev_routes: true,
  observers: [
    Thorchain,
    Rujira.Balances,
    Rujira.Bank,
    Rujira.Chains,
    Rujira.Contracts,
    Rujira.Fin,
    Rujira.Merge,
    Rujira.Staking,
    Rujira.Leagues,
    Rujira.Bow,
    Rujira.Index
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n", level: :debug

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

network = System.get_env("NETWORK", "stagenet")
import_config "dev.#{network}.exs"
