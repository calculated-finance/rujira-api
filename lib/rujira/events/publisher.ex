defmodule Rujira.Events.Publisher do
  @moduledoc """
  Defines the behaviour for publishing events to GraphQL subscriptions.

  This behaviour specifies the interface that all event publishers must implement
  to support real-time updates in the GraphQL API.
  """
  @callback publish(
              Absinthe.Subscription.Pubsub.t(),
              term(),
              Absinthe.Resolution.t() | [Absinthe.Subscription.subscription_field_spec()]
            ) :: :ok
end
