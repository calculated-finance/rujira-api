defmodule RujiraWeb.Schema.AnalyticsTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Rujira.Assets
  alias RujiraWeb.Resolvers

  object :analytics do
    field :swap, non_null(:analytics_swap) do
      resolve(fn _, _, _ -> {:ok, %{swap: %{}}} end)
    end
  end

  connection(node_type: :analytics_swap_snapshot)

  object :analytics_swap do
    connection field :snapshots, node_type: :analytics_swap_snapshot do
      arg(:from, non_null(:timestamp))
      arg(:to, non_null(:timestamp))
      arg(:resolution, non_null(:resolution))
      arg(:period, non_null(:integer))
      resolve(&Resolvers.Analytics.swap_snapshots/3)
    end
  end

  object :analytics_swap_snapshot do
    field :resolution, non_null(:resolution)
    field :bin, non_null(:timestamp)
    field :swap_volume_by_asset, list_of(non_null(:analytics_swap_snapshot_asset))
    field :swap_volume_by_chain, list_of(non_null(:analytics_swap_snapshot_chain))
    field :unique_swap_users, non_null(:bigint)
    @desc "moving average on the number of swaps"
    field :swaps, non_null(:point)
    field :volume, non_null(:point)
    @desc "rujira volume share over total volume generated on Thorchain"
    field :volume_share_over_total, non_null(:bigint)
    @desc "moving average on the liquidity fee paid to thorchain"
    field :liquidity_fee_paid_to_tc, non_null(:point)
    @desc "rujira liquidity fee share over total liquidity fee collected by thorchain"
    field :liquidity_fee_paid_to_tc_share_over_total, non_null(:bigint)
    @desc "moving average on the affiliate fee"
    field :affiliate_fee, non_null(:point)
  end

  object :analytics_swap_snapshot_asset do
    field :asset, non_null(:asset) do
      resolve(fn %{asset: asset}, _, _ ->
        {:ok, Assets.from_string(asset)}
      end)
    end

    field :volume, non_null(:bigint)
    field :weight, non_null(:bigint)
  end

  object :analytics_swap_snapshot_chain do
    field :chain, non_null(:chain)
    field :volume, non_null(:bigint)
    field :weight, non_null(:bigint)
  end
end
