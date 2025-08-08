defmodule RujiraWeb.Fragments.PilotFragments do
  @moduledoc false

  alias RujiraWeb.Fragments.AssetFragments
  alias RujiraWeb.Fragments.BalanceFragments

  @asset_fragment AssetFragments.get_asset_fragment()
  @balance_fragment BalanceFragments.get_balance_fragment()

  @pilot_bid_action_fragment """
  fragment PilotBidActionFragment on PilotBidAction {
    contract
    txhash
    owner
    premium
    amount
    height
    tx_idx
    idx
    type
    timestamp
  }
  """

  @pilot_pool_fragment """
  fragment PilotPoolFragment on PilotPool {
    slot
    premium
    rate
    epoch
    total
  }
  """

  @pilot_pools_fragment """
  fragment PilotPoolsFragment on PilotBidPools {
    id
    pools {
      ...PilotPoolFragment
    }
  }
  #{@pilot_pool_fragment}
  """

  @pilot_sale_fragment """
  fragment PilotSaleFragment on PilotSale {
    address
    bidAsset{
      ...AssetFragment
    }
    bidPools {
      ...PilotPoolsFragment
    }
    bidThreshold
    closes
    deposit {
      ...BalanceFragment
    }
    feeAmount
    maxPremium
    opens
    price
    raiseAmount
    waitingPeriod
    avgPrice
    duration
    completionPercentage
    totalBids
    history(first: 10) {
      edges {
        node {
          ...PilotBidActionFragment
        }
      }
    }
  }
  #{@pilot_bid_action_fragment}
  #{@balance_fragment}
  #{@pilot_pools_fragment}
  #{@asset_fragment}
  """

  @pilot_bid_fragment """
  fragment PilotBidFragment on PilotBid {
    id
    owner
    sale
    offer
    premium
    rate
    remaining
    filled
    slot
    updatedAt
  }
  """

  @pilot_account_fragment """
  fragment PilotAccountFragment on PilotAccount {
    id
    sale
    account
    summary {
      avgDiscount
      totalTokens
      value
      avgPrice
      totalBids
    }
    bids(first: 10) {
      edges {
        node {
          ...PilotBidFragment
        }
      }
    }
    history(first: 10) {
      edges {
        node {
          ...PilotBidActionFragment
        }
      }
    }
  }
  #{@pilot_bid_fragment}
  #{@pilot_bid_action_fragment}
  """

  def get_pilot_sale_fragment, do: @pilot_sale_fragment
  def get_pilot_pools_fragment, do: @pilot_pools_fragment
  def get_pilot_bid_fragment, do: @pilot_bid_fragment
  def get_pilot_account_fragment, do: @pilot_account_fragment
  def get_pilot_bid_action_fragment, do: @pilot_bid_action_fragment
end
