defmodule RujiraWeb.Fragments.BowFragments do
  @moduledoc false

  alias RujiraWeb.Fragments.AssetFragments
  alias RujiraWeb.Fragments.BalanceFragments
  alias RujiraWeb.Fragments.DeveloperFragments
  alias RujiraWeb.Fragments.FinFragments

  @asset_fragment AssetFragments.get_asset_fragment()
  @balance_fragment BalanceFragments.get_balance_fragment()
  @contract_info_fragment DeveloperFragments.get_contract_info_fragment()
  @fin_book_fragment FinFragments.get_fin_book_fragment()
  @fin_trade_fragment FinFragments.get_fin_trade_fragment()

  @bow_config_xyk_fragment """
  fragment BowConfigXykFragment on BowConfigXyk {
    x {
      ...AssetFragment
    }
    y {
      ...AssetFragment
    }
    shareAsset {
      ...AssetFragment
    }
    step
    minQuote
    fee
  }
  #{@asset_fragment}
  """

  @bow_state_xyk_fragment """
  fragment BowStateXykFragment on BowStateXyk {
    x
    y
    k
    shares
  }
  """

  @bow_summary_fragment """
  fragment BowSummaryFragment on BowSummary {
    spread
    depthBid
    depthAsk
    volume
    utilization
  }
  """

  @bow_config_fragment """
  fragment BowConfigFragment on BowConfig {
    ... on BowConfigXyk {
      ...BowConfigXykFragment
    }
  }
  #{@bow_config_xyk_fragment}
  """

  @bow_state_fragment """
  fragment BowStateFragment on BowState {
    ... on BowStateXyk {
      ...BowStateXykFragment
    }
  }
  #{@bow_state_xyk_fragment}
  """

  @bow_pool_fragment """
  fragment BowPoolFragment on BowPool {
    id
    address
    contract {
      ...ContractInfoFragment
    }
    config {
      ...BowConfigFragment
    }
    state {
      ...BowStateFragment
    }
    summary {
      ...BowSummaryFragment
    }
    quotes {
      ...FinBookFragment
    }
    deploymentStatus
  }
  #{@bow_config_fragment}
  #{@bow_state_fragment}
  #{@bow_summary_fragment}
  #{@contract_info_fragment}
  #{@fin_book_fragment}
  """

  @bow_account_fragment """
  fragment BowAccountFragment on BowAccount {
    id
    account
    pool {
      id
      address
    }
    shares {
      ...BalanceFragment
    }
    value {
      ...BalanceFragment
    }
    valueUsd
  }
  #{@balance_fragment}
  """

  @bow_pool_xyk_fragment """
  fragment BowPoolXykFragment on BowPoolXyk {
    address
    contract {
      ...ContractInfoFragment
    }
    config {
      ...BowConfigXykFragment
    }
    state {
      ...BowStateXykFragment
    }
    summary {
      ...BowSummaryFragment
    }
    quotes {
      ...FinBookFragment
    }
    trades {
      ...FinTradeFragment
    }
    deploymentStatus
  }
  #{@bow_config_xyk_fragment}
  #{@bow_state_xyk_fragment}
  #{@bow_summary_fragment}
  #{@contract_info_fragment}
  #{@fin_book_fragment}
  #{@fin_trade_fragment}
  """

  def get_bow_config_xyk_fragment, do: @bow_config_xyk_fragment
  def get_bow_state_xyk_fragment, do: @bow_state_xyk_fragment
  def get_bow_summary_fragment, do: @bow_summary_fragment
  def get_bow_pool_xyk_fragment, do: @bow_pool_xyk_fragment
  def get_bow_pool_fragment, do: @bow_pool_fragment
  def get_bow_config_fragment, do: @bow_config_fragment
  def get_bow_state_fragment, do: @bow_state_fragment
  def get_bow_account_fragment, do: @bow_account_fragment
end
