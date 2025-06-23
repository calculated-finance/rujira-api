defmodule RujiraWeb.Schema.Thorchain.AnalyticsTypes do
  @moduledoc """
  Defines GraphQL types for Thorchain Analytics data in the Rujira API.

  This module contains the type definitions and field resolvers for Thorchain
  analytics, including pool metrics, volume, and performance statistics.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Rujira.Assets
  alias RujiraWeb.Resolvers.Thorchain.Analytics

  object :thorchain_analytics do
    field :pools, non_null(:thorchain_analytics_pools) do
      resolve(fn _, _, _ -> {:ok, %{pools: %{}}} end)
    end

    field :pool, non_null(:thorchain_analytics_pool) do
      resolve(fn _, _, _ -> {:ok, %{pool: %{}}} end)
    end
  end

  connection(node_type: :thorchain_analytics_pool_snapshot)
  connection(node_type: :thorchain_analytics_pools_snapshot)

  object :thorchain_analytics_pools do
    connection field :snapshots, node_type: :thorchain_analytics_pools_snapshot do
      arg(:after, non_null(:timestamp))
      arg(:before, non_null(:timestamp))
      arg(:first, :integer, default_value: 100)
      arg(:resolution, non_null(:resolution))
      arg(:period, non_null(:integer))
      resolve(&Analytics.pools_snaps/3)
    end

    field :pools, non_null(list_of(non_null(:thorchain_analytics_pool_overview))) do
      resolve(&Analytics.pools_overview/3)
    end
  end

  object :thorchain_analytics_pools_snapshot do
    field :resolution, non_null(:resolution)
    field :bin, non_null(:timestamp)
    field :tvl_end_of_bin, non_null(:bigint)
    @desc "join with pool_snap slect * from pool snap -> manipulate per asset"
    field :tvl_by_asset, non_null(list_of(non_null(:thorchain_analytics_pools_snapshot_asset)))
    @desc "join with pool_snap slect * from pool snap -> manipulate per chain"
    field :tvl_by_chain, non_null(list_of(non_null(:thorchain_analytics_pools_snapshot_chain)))
    @desc "unique addresses that have swapped at least once in this time interval"
    field :unique_swap_users, non_null(:bigint)
    @desc "unique addresses that have deposited at least once in this time interval"
    field :unique_deposit_users, non_null(:bigint)
    @desc "unique addresses that have withdrawn at least once in this time interval"
    field :unique_withdraw_users, non_null(:bigint)
    @desc "this is in dollar value (asset + rune) at the time of deposit"
    field :deposits_value, non_null(:bigint)
    @desc "this is in dollar value (asset + rune) at the time of withdrawal"
    field :withdrawals_value, non_null(:bigint)
    @desc "number of swaps"
    field :swaps, non_null(:point)
    @desc "volume"
    field :volume, non_null(:point)
    @desc "earnings"
    field :earnings, non_null(:point)
    @desc "liquidity utilization"
    field :liquidity_utilization, non_null(:point)
  end

  object :thorchain_analytics_pools_snapshot_asset do
    field :asset, non_null(:asset) do
      resolve(fn %{asset: asset}, _, _ ->
        {:ok, Assets.from_string(asset)}
      end)
    end

    field :tvl, non_null(:bigint)
    field :weight, non_null(:bigint)
  end

  object :thorchain_analytics_pools_snapshot_chain do
    field :chain, non_null(:chain)
    field :tvl, non_null(:bigint)
    field :weight, non_null(:bigint)
  end

  object :thorchain_analytics_pool_overview do
    field :asset, non_null(:asset) do
      resolve(fn %{asset: asset}, _, _ ->
        {:ok, Assets.from_string(asset)}
      end)
    end

    field :tvl, non_null(:bigint)
    field :volume_24h, non_null(:bigint)
    field :volume_30d, non_null(:bigint)
    field :daily_liquidity_utilization, non_null(:point)
    field :apr_30d, non_null(:bigint)
  end

  object :thorchain_analytics_pool do
    field :aggregated, non_null(:thorchain_analytics_pool_snapshot) do
      arg(:after, non_null(:timestamp))
      arg(:before, non_null(:timestamp))
      arg(:asset, non_null(:asset_string))
      @desc "Period used for Point moving averages"
      arg(:period, non_null(:integer))
      resolve(&Analytics.pool_aggregated_data/3)
    end

    connection field :snapshots, node_type: :thorchain_analytics_pool_snapshot do
      arg(:after, non_null(:timestamp))
      arg(:before, non_null(:timestamp))
      arg(:first, :integer, default_value: 100)
      arg(:resolution, non_null(:resolution))
      arg(:asset, non_null(:asset_string))
      @desc "Period used for Point moving averages"
      arg(:period, non_null(:integer))
      resolve(&Analytics.pool_snaps/3)
    end
  end

  object :thorchain_analytics_pool_snapshot do
    field :asset, non_null(:asset) do
      resolve(fn %{asset: asset}, _, _ ->
        {:ok, Assets.from_string(asset)}
      end)
    end

    field :resolution, non_null(:resolution)
    field :bin, non_null(:timestamp)
    field :open, non_null(:thorchain_analytics_pool_assets)
    field :close, non_null(:thorchain_analytics_pool_assets)

    field :deposits, non_null(:thorchain_analytics_pool_flow)
    field :withdrawals, non_null(:thorchain_analytics_pool_flow)

    field :impermanent_loss, non_null(:bigint)
    field :price_pl, non_null(:bigint)
    field :earnings, non_null(:bigint)
    field :earnings_per_lp_unit, non_null(:bigint)
    field :apr, non_null(:point)
    field :price_pl_approx, non_null(:bigint)
    field :volume, non_null(:point)
    field :liquidity_utilization, non_null(:point)
  end

  object :thorchain_analytics_pool_assets do
    field :balance_asset, non_null(:bigint)
    field :balance_rune, non_null(:bigint)
    field :price_asset, non_null(:bigint)
    field :price_rune, non_null(:bigint)
    field :value, non_null(:bigint)
    field :lp_units, non_null(:bigint)
  end

  object :thorchain_analytics_pool_flow do
    field :value, non_null(:bigint)
    field :asset_quantity, non_null(:bigint)
    field :rune_quantity, non_null(:bigint)
  end

  object :point do
    field :value, non_null(:bigint)
    field :moving_avg, non_null(:bigint)
  end
end
