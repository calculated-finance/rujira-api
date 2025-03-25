defmodule RujiraWeb.Schema.Rujira.AnalyticsTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Rujira.Assets
  alias RujiraWeb.Resolvers

  object :rujira_analytics do
    field :ruji_swap, non_null(:ruji_swap) do
      resolve(fn _, _, _ -> {:ok, %{ruji_swap: %{}}} end)
    end
  end

  connection(node_type: :ruji_swap_snap)

  object :ruji_swap do
    connection field :snapshots, node_type: :ruji_swap_snap do
      arg(:after, non_null(:timestamp))
      arg(:before, non_null(:timestamp))
      arg(:first, :integer, default_value: 100)
      arg(:resolution, non_null(:resolution))
      arg(:ma_period, non_null(:integer))
      resolve(&Resolvers.Analytics.ruji_swaps_snaps/3)
    end
  end

  object :ruji_swap_snap do
    field :resolution, non_null(:resolution)
    field :bin_open_time, non_null(:timestamp)
    field :swap_volume_by_asset, non_null(list_of(non_null(:ruji_swap_distribution_by_asset)))
    field :swap_volume_by_chain, non_null(list_of(non_null(:ruji_swap_distribution_by_chain)))
    field :unique_swap_users, non_null(:bigint)
    field :swaps_num, non_null(:bigint)
    field :swaps_num_ma, non_null(:bigint) # moving average on the number of swaps
    field :volume, non_null(:bigint)
    field :volume_share_over_total, non_null(:bigint) # rujira volume share over total volume generated on Thorchain
    field :volume_ma, non_null(:bigint) # moving average on the volume
    field :liquidity_fee_paid_to_tc, non_null(:bigint)
    field :liquidity_fee_paid_to_tc_share_over_total, non_null(:bigint) # rujira liquidity fee share over total liquidity fee collected by thorchain
    field :liquidity_fee_paid_to_tc_ma, non_null(:bigint) # moving average on the liquidity fee paid to thorchain
    field :affiliate_fee, non_null(:bigint)
    field :affiliate_fee_ma, non_null(:bigint) # moving average on the affiliate fee
  end

  object :ruji_swap_distribution_by_asset do
    field :asset, non_null(:asset) do
      resolve(fn %{asset: asset}, _, _ ->
        {:ok, Assets.from_string(asset)}
      end)
    end
    field :volume, non_null(:bigint)
    field :weight, non_null(:bigint)
  end

  object :ruji_swap_distribution_by_chain do
    field :chain, non_null(:chain)
    field :volume, non_null(:bigint)
    field :weight, non_null(:bigint)
  end
end
