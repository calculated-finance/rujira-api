defmodule RujiraWeb.Fragments.MergeFragments do
  alias RujiraWeb.Fragments.AssetFragments

  @asset_fragment AssetFragments.get_asset_fragment()

  @merge_status_fragment """
  fragment MergeStatusFragment on MergeStatus {
    merged
    shares
    size
    currentRate
    shareValue
    shareValueChange
    apr
  }
  """

  @merge_pool_fragment """
  fragment MergePoolFragment on MergePool {
    id
    address
    contract {
      admin
      label
    }
    mergeAsset {
      ...AssetFragment
    }
    mergeSupply
    rujiAsset {
      ...AssetFragment
    }
    rujiAllocation
    decayStartsAt
    decayEndsAt
    currentRate
    startRate
    status {
      ...MergeStatusFragment
    }
  }
  #{@merge_status_fragment}
  #{@asset_fragment}
  """

  @merge_account_fragment """
  fragment MergeAccountFragment on MergeAccount {
    id
    pool {
      id
      address
    }
    merged {
      amount
      asset {
        ...AssetFragment
      }
    }
    shares
    size {
      amount
      asset {
        ...AssetFragment
      }
    }
    rate
  }
  #{@asset_fragment}
  """

  @merge_stats_fragment """
  fragment MergeStatsFragment on MergeStats {
    totalSize {
      amount
      asset {
        ...AssetFragment
      }
    }
    accounts {
      ...MergeAccountFragment
    }
  }
  #{@merge_account_fragment}
  #{@asset_fragment}
  """

  def get_merge_status_fragment(), do: @merge_status_fragment
  def get_merge_pool_fragment(), do: @merge_pool_fragment
  def get_merge_account_fragment(), do: @merge_account_fragment
  def get_merge_stats_fragment(), do: @merge_stats_fragment
end
