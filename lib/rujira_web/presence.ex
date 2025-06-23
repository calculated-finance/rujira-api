defmodule RujiraWeb.Presence do
  @moduledoc false
  use Phoenix.Presence,
    otp_app: :rujira,
    pubsub_server: Rujira.PubSub
end
