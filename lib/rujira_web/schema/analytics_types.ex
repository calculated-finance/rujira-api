defmodule RujiraWeb.Schema.AnalyticsTypes do
  @moduledoc """
  Defines GraphQL types for analytics data in the Rujira API.

  This module contains the type definitions and field resolvers for analytics-related
  GraphQL objects, including swap analytics and other metrics.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  # import types
  import_types(RujiraWeb.Schema.Analytics.SwapTypes)
  import_types(RujiraWeb.Schema.Analytics.StakingTypes)

  # Analytics main object
  object :analytics do
    field :swap, non_null(:analytics_swap) do
      resolve(fn _, _, _ -> {:ok, %{swap: %{}}} end)
    end

    field :staking, non_null(:analytics_staking) do
      resolve(fn _, _, _ -> {:ok, %{staking: %{}}} end)
    end
  end

  # ---- Common Types ----
  object :point do
    field :value, non_null(:bigint)
    field :moving_avg, non_null(:bigint)
  end
end
