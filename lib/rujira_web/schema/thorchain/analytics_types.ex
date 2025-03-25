defmodule RujiraWeb.Schema.Thorchain.AnalyticsTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Rujira.Assets
  alias RujiraWeb.Resolvers

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
      arg(:ma_period, non_null(:integer))
      resolve(&Resolvers.Thorchain.Analytics.pools_snaps/3)
    end

    field :pools, non_null(list_of(non_null(:thorchain_analytics_pool_overview))) do
      resolve(&Resolvers.Thorchain.Analytics.pools_overview/3)
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
    field :swaps_num, non_null(:bigint)
    @desc "moving average on the number of swaps"
    field :swaps_num_moving_avg, non_null(:bigint)
    field :volume, non_null(:bigint)
    @desc "moving average on the volume"
    field :volume_moving_avg, non_null(:bigint)
    field :earnings, non_null(:bigint)
    @desc "moving average on the earnings"
    field :earnings_moving_avg, non_null(:bigint)
    field :liquidity_utilization, non_null(:bigint)
    @desc "moving average on the liquidity utilization"
    field :liquidity_utilization_moving_avg, non_null(:bigint)
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
    field :daily_liquidity_utilization, non_null(:bigint)
    field :daily_liquidity_utilization_moving_avg_30, non_null(:bigint)
    field :apr_30d, non_null(:bigint)
  end

  object :thorchain_analytics_pool do
    field :aggregated, non_null(:thorchain_analytics_pool_snapshot) do
      arg(:after, non_null(:timestamp))
      arg(:before, non_null(:timestamp))
      arg(:asset, non_null(:asset_string))
      arg(:ma_period, non_null(:integer))
      resolve(&Resolvers.Thorchain.Analytics.pool_aggregated_data/3)
    end

    connection field :snapshots, node_type: :thorchain_analytics_pool_snapshot do
      arg(:after, non_null(:timestamp))
      arg(:before, non_null(:timestamp))
      arg(:first, :integer, default_value: 100)
      arg(:resolution, non_null(:resolution))
      arg(:asset, non_null(:asset_string))
      arg(:ma_period, non_null(:integer))
      resolve(&Resolvers.Thorchain.Analytics.pool_snaps/3)
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
    field :apr, non_null(:bigint)
    field :apr_moving_avg, non_null(:bigint)
    field :price_pl_approx, non_null(:bigint)
    field :volume, non_null(:bigint)
    field :volume_moving_avg, non_null(:bigint)
    field :liquidity_utilization, non_null(:bigint)
    field :liquidity_utilization_moving_avg, non_null(:bigint)
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
end
