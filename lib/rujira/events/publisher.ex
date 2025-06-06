defmodule Rujira.Events.Publisher do
  @callback publish(
              Absinthe.Subscription.Pubsub.t(),
              term(),
              Absinthe.Resolution.t() | [Absinthe.Subscription.subscription_field_spec()]
            ) :: :ok
end
