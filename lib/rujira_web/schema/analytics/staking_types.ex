defmodule RujiraWeb.Schema.Analytics.StakingTypes do
  @moduledoc """
  Defines GraphQL types for analytics staking data in the Rujira API.

  This module contains the type definitions and field resolvers for analytics-related
  GraphQL objects, including staking analytics and other metrics.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias RujiraWeb.Resolvers

  connection(node_type: :analytics_staking_bins)

  #  ---- Staking Analytics ----
  object :analytics_staking do
    connection field :bins, node_type: :analytics_staking_bins do
      arg(:from, non_null(:timestamp))
      arg(:to, non_null(:timestamp))
      # contract address of single side staking
      arg(:contract, non_null(:address))
      arg(:resolution, non_null(:resolution))
      arg(:period, non_null(:integer))
      resolve(&Resolvers.Analytics.staking_bins/3)
    end
  end

  object :analytics_staking_bins do
    field :resolution, non_null(:resolution)
    field :bin, non_null(:timestamp)

    # lp weight -> if single side == 1 otherwise proportion of base denom / lp
    # 1 lp = 100 ruji => 1%
    field :lp_weight, non_null(:bigint)

    # revenue data in USD
    field :total_revenue, non_null(:point)
    field :account_revenue, non_null(:point)
    field :liquid_revenue, non_null(:point)

    # APR data
    field :account_apr, non_null(:point)
    field :liquid_apy, non_null(:point)
    # revenue per share in USD * lp_weight
    field :account_revenue_per_share, non_null(:point)

    # staking amount data in bond denom
    field :total_balance_staked, non_null(:point)
    field :account_balance_staked, non_null(:point)
    field :liquid_balance_staked, non_null(:point)

    field :liquid_weight, non_null(:bigint) do
      resolve(fn %{
                   liquid_balance_staked: liquid_balance_staked,
                   total_balance_staked: total_balance_staked
                 },
                 _,
                 _ ->
        if total_balance_staked.value == 0 do
          {:ok, 0}
        else
          {:ok, Decimal.div(liquid_balance_staked.value, total_balance_staked.value)}
        end
      end)
    end

    # staking value data in USD
    field :total_value_staked, non_null(:point)
    field :account_value_staked, non_null(:point)
    field :liquid_value_staked, non_null(:point)

    # inflow data in bond denom
    field :inflow_account_staked, non_null(:point)
    field :inflow_liquid_staked, non_null(:point)
    field :inflow_total_staked, non_null(:point)

    # outflow data in bond denom
    field :outflow_account_staked, non_null(:point)
    field :outflow_liquid_staked, non_null(:point)
    field :outflow_total_staked, non_null(:point)

    field :net_flow_account_staked, non_null(:bigint) do
      resolve(fn %{
                   inflow_account_staked: inflow_account_staked,
                   outflow_account_staked: outflow_account_staked
                 },
                 _,
                 _ ->
        {:ok, Decimal.sub(inflow_account_staked.value, outflow_account_staked.value)}
      end)
    end

    field :net_flow_liquid_staked, non_null(:bigint) do
      resolve(fn %{
                   inflow_liquid_staked: inflow_liquid_staked,
                   outflow_liquid_staked: outflow_liquid_staked
                 },
                 _,
                 _ ->
        {:ok, Decimal.sub(inflow_liquid_staked.value, outflow_liquid_staked.value)}
      end)
    end

    field :net_flow_total_staked, non_null(:bigint) do
      resolve(fn %{
                   inflow_total_staked: inflow_total_staked,
                   outflow_total_staked: outflow_total_staked
                 },
                 _,
                 _ ->
        {:ok, Decimal.sub(inflow_total_staked.value, outflow_total_staked.value)}
      end)
    end
  end
end
