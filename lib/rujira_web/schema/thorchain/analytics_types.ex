defmodule RujiraWeb.Schema.Thorchain.AnalyticsTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Rujira.Assets
  alias RujiraWeb.Resolvers

  object :thorchain_analytics do
    field :pools_overview, non_null(:pools_overview) do
      resolve(fn _, _, _ -> {:ok, %{pools_overview: %{}}} end)
    end
    field :pool, non_null(:pool_analytics) do
      resolve(fn _, _, _ -> {:ok, %{pool_analytics: %{}}} end)
    end
  end

  connection(node_type: :pool_snap)
  connection(node_type: :pools_overview_snap)

  object :pools_overview do
    connection field :snapshots, node_type: :pools_overview_snap do
      arg(:after, non_null(:timestamp))
      arg(:before, non_null(:timestamp))
      arg(:first, :integer, default_value: 100)
      arg(:resolution, non_null(:resolution))
      arg(:ma_period, non_null(:integer))
      resolve(&Resolvers.Thorchain.Analytics.pools_snaps/3)
    end

    field :pools, non_null(list_of(non_null(:pool_overview))) do
      resolve(&Resolvers.Thorchain.Analytics.pools_overview/3)
    end
  end

  object :pools_overview_snap do
    field :resolution, non_null(:resolution)
    field :bin_open_time, non_null(:timestamp)
    field :tvl_end_of_bin, non_null(:bigint)
    # join with pool_snap slect * from pool snap -> manipulate per asset
    field :tvl_by_asset, non_null(list_of(non_null(:pool_distribution_by_asset)))
    # join with pool_snap slect * from pool snap -> manipulate per chain
    field :tvl_by_chain, non_null(list_of(non_null(:pool_distribution_by_chain)))
    # unique addresses that have swapped at least once in this time interval
    field :unique_swap_users, non_null(:bigint)
    # unique addresses that have deposited at least once in this time interval
    field :unique_deposit_users, non_null(:bigint)
    # unique addresses that have withdrawn at least once in this time interval
    field :unique_withdraw_users, non_null(:bigint)
    field :deposits_value, non_null(:bigint) # this is in dollar value (asset + rune) at the time of deposit
    field :withdrawals_value, non_null(:bigint) # this is in dollar value (asset + rune) at the time of withdrawal
    field :swaps_num, non_null(:bigint)
    field :swaps_num_ma, non_null(:bigint) # moving average on the number of swaps
    field :volume, non_null(:bigint)
    field :volume_ma, non_null(:bigint) # moving average on the volume
    field :earnings, non_null(:bigint)
    field :earnings_ma, non_null(:bigint) # moving average on the earnings
    field :liquidity_utilization, non_null(:bigint)
    field :liquidity_utilization_ma, non_null(:bigint) # moving average on the liquidity utilization
  end

  object :pool_distribution_by_asset do
    field :asset, non_null(:asset) do
      resolve(fn %{asset: asset}, _, _ ->
        {:ok, Assets.from_string(asset)}
      end)
    end
    field :tvl, non_null(:bigint)
    field :weight, non_null(:bigint)
  end

  object :pool_distribution_by_chain do
    field :chain, non_null(:chain)
    field :tvl, non_null(:bigint)
    field :weight, non_null(:bigint)
  end

  object :pool_overview do
    field :asset, non_null(:asset) do
      resolve(fn %{asset: asset}, _, _ ->
        {:ok, Assets.from_string(asset)}
      end)
    end
    field :tvl, non_null(:bigint)
    field :volume_24h, non_null(:bigint)
    field :volume_30d, non_null(:bigint)
    field :daily_liquidity_utilization, non_null(:bigint)
    field :daily_liquidity_utilization_ma30, non_null(:bigint)
    field :apr_30d, non_null(:bigint)
  end

  object :pool_analytics do
    field :aggregated, non_null(:pool_snap) do
      arg(:after, non_null(:timestamp))
      arg(:before, non_null(:timestamp))
      arg(:asset, non_null(:asset_string))
      arg(:ma_period, non_null(:integer))
      resolve(&Resolvers.Thorchain.Analytics.pool_aggregated_data/3)
    end

    connection field :snapshots, node_type: :pool_snap do
      arg(:after, non_null(:timestamp))
      arg(:before, non_null(:timestamp))
      arg(:first, :integer, default_value: 100)
      arg(:resolution, non_null(:resolution))
      arg(:asset, non_null(:asset_string))
      arg(:ma_period, non_null(:integer))
      resolve(&Resolvers.Thorchain.Analytics.pool_snaps/3)
    end
  end

  object :pool_snap do
    field :asset, non_null(:asset) do
      resolve(fn %{asset: asset}, _, _ ->
        {:ok, Assets.from_string(asset)}
      end)
    end
    field :resolution, non_null(:resolution)
    field :bin_open_time, non_null(:timestamp)
    field :opening_balance_asset, non_null(:bigint)
    field :opening_balance_rune, non_null(:bigint)
    field :opening_price_asset, non_null(:bigint)
    field :opening_price_rune, non_null(:bigint)
    field :opening_value, non_null(:bigint)
    field :opening_lp_units, non_null(:bigint)

    field :closing_balance_asset, non_null(:bigint)
    field :closing_balance_rune, non_null(:bigint)
    field :closing_price_asset, non_null(:bigint)
    field :closing_price_rune, non_null(:bigint)
    field :closing_value, non_null(:bigint)
    field :closing_lp_units, non_null(:bigint)

    field :deposits_value, non_null(:bigint)
    field :deposits_asset_quantity, non_null(:bigint)
    field :deposits_rune_quantity, non_null(:bigint)
    field :withdrawals_value, non_null(:bigint)
    field :withdrawals_asset_quantity, non_null(:bigint)
    field :withdrawals_rune_quantity, non_null(:bigint)

    field :impermanent_loss, non_null(:bigint)
    field :price_pl, non_null(:bigint)
    field :earnings, non_null(:bigint)
    field :earnings_per_lp_unit, non_null(:bigint)
    field :apr, non_null(:bigint)
    field :apr_ma, non_null(:bigint)
    field :price_pl_approx, non_null(:bigint)
    field :volume, non_null(:bigint)
    field :volume_ma, non_null(:bigint)
    field :liquidity_utilization, non_null(:bigint)
    field :liquidity_utilization_ma, non_null(:bigint)
  end
end
