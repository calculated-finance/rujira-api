defmodule RujiraWeb.Fragments.FinFragments do
  @moduledoc false

  alias RujiraWeb.Fragments.AssetFragments
  alias RujiraWeb.Fragments.BalanceFragments
  alias RujiraWeb.Fragments.DeveloperFragments
  alias RujiraWeb.Fragments.ThorchainFragments

  @asset_fragment AssetFragments.get_asset_fragment()
  @contract_info_fragment DeveloperFragments.get_contract_info_fragment()
  @thorchain_oracle_fragment ThorchainFragments.get_thorchain_oracle_fragment()
  @layer_1_balance_fragment BalanceFragments.get_layer1_balance_fragment()

  @fin_book_entry_fragment """
  fragment FinBookEntryFragment on FinBookEntry {
    price
    total
    side
    value
  }
  """

  @fin_book_fragment """
  fragment FinBookFragment on FinBook {
    asks {
      ...FinBookEntryFragment
    }
    center
    spread
    bids {
      ...FinBookEntryFragment
    }
    pair {
      id
      address
    }
  }
  #{@fin_book_entry_fragment}
  """

  @fin_trade_fragment """
  fragment FinTradeFragment on FinTrade {
    height
    txIdx
    idx
    contract
    txhash
    quoteAmount
    baseAmount
    price
    type
    protocol
    timestamp
    assetBase {
      ...AssetFragment
    }
    assetQuote {
      ...AssetFragment
    }
  }
  #{@asset_fragment}
  """

  @fin_candle_fragment """
  fragment FinCandleFragment on FinCandle {
    resolution
    high
    low
    open
    close
    volume
    bin
  }
  """

  @fin_summary_fragment """
  fragment FinSummaryFragment on FinSummary {
    last
    lastUsd
    high
    low
    change
    volume {
      ...Layer1BalanceFragment
    }
  }
  #{@layer_1_balance_fragment}
  """

  @fin_pair_summary_fragment """
  fragment FinPairSummaryFragment on FinPairSummary {
    last
    lastUsd
    high
    low
    change
    volume {
      ...Layer1BalanceFragment
    }
  }
  #{@layer_1_balance_fragment}
  """

  @fin_pair_fragment """
  fragment FinPairFragment on FinPair {
    id
    address
    contract {
      ...ContractInfoFragment
    }
    assetBase {
      ...AssetFragment
    }
    assetQuote {
      ...AssetFragment
    }
    oracleBase {
    ...ThorchainOracleFragment
    }
    oracleQuote {
    ...ThorchainOracleFragment
    }
    tick
    feeTaker
    feeMaker
    feeAddress
    book {
      ...FinBookFragment
    }
    summary {
      ...FinSummaryFragment
    }
  }
  #{@fin_book_fragment}
  #{@fin_summary_fragment}
  #{@contract_info_fragment}
  #{@thorchain_oracle_fragment}
  """

  @fin_order_fragment """
  fragment FinOrderFragment on FinOrder {
    id
    owner
    side
    rate
    updatedAt
    offer
    offerValue
    remaining
    remainingValue
    filled
    filledValue
    filledFee
    valueUsd
    type
    deviation
    pair {
    ...FinPairFragment
    }
  }
  #{@fin_pair_fragment}
  """

  @fin_account_action_fragment """
  fragment FinAccountActionFragment on FinAccountAction {
    type
    height
    txIdx
    idx
    contract
    txhash
    quoteAmount
    baseAmount
    price
    protocol
    timestamp
    assetBase {
      ...AssetFragment
    }
    assetQuote {
      ...AssetFragment
    }
  }
  #{@asset_fragment}
  """

  @fin_account_fragment """
  fragment FinAccountFragment on FinAccount {
    orders(first: 10) {
      edges {
        node {
          ...FinOrderFragment
        }
      }
    }
    history(first: 10) {
      edges {
        node {
          ...FinAccountActionFragment
        }
      }
    }
  }
  #{@fin_order_fragment}
  #{@fin_account_action_fragment}
  """

  def get_fin_book_entry_fragment, do: @fin_book_entry_fragment
  def get_fin_book_fragment, do: @fin_book_fragment
  def get_fin_order_fragment, do: @fin_order_fragment
  def get_fin_trade_fragment, do: @fin_trade_fragment
  def get_fin_candle_fragment, do: @fin_candle_fragment
  def get_fin_summary_fragment, do: @fin_summary_fragment
  def get_fin_pair_summary_fragment, do: @fin_pair_summary_fragment
  def get_fin_pair_fragment, do: @fin_pair_fragment
  def get_fin_account_action_fragment, do: @fin_account_action_fragment
  def get_fin_account_fragment, do: @fin_account_fragment
end
