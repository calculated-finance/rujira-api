defmodule RujiraWeb.Presence do
  use Phoenix.Presence,
    otp_app: :rujira,
    pubsub_server: Rujira.PubSub
end
