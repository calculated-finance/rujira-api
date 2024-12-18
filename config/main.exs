import Config

config :logger, level: :info

config :rujira, Thorchain.Node,
  websocket: "",
  subscriptions: ["tm.event='NewBlock'"],
  grpcs: []
