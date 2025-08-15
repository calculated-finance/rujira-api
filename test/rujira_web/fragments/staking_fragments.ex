defmodule RujiraWeb.Fragments.StakingFragments do
  @moduledoc false
  alias RujiraWeb.Fragments.AprFragments
  alias RujiraWeb.Fragments.AssetFragments
  alias RujiraWeb.Fragments.BalanceFragments
  alias RujiraWeb.Fragments.DeveloperFragments

  @asset_fragment AssetFragments.get_asset_fragment()
  @contract_info_fragment DeveloperFragments.get_contract_info_fragment()
  @balance_fragment BalanceFragments.get_balance_fragment()
  @apr_fragment AprFragments.get_apr_fragment()

  @staking_status_fragment """
  fragment StakingStatusFragment on StakingStatus {
    accountBond
    accountRevenue
    liquidBondShares
    liquidBondSize
    pendingRevenue
  }
  """

  @revenue_converter_type_fragment """
  fragment RevenueConverterTypeFragment on RevenueConverterType {
    address
    contract {
      ...ContractInfoFragment
    }
    executeMsg
    limit
  }
  #{@contract_info_fragment}
  """

  @revenue_converter_fragment """
  fragment RevenueConverterFragment on RevenueConverter {
    balances {
      ...BalanceFragment
    }
    targetAssets {
      ...AssetFragment
    }
    targetAddresses
  }
  #{@asset_fragment}
  #{@balance_fragment}
  """

  @staking_revenue_point_fragment """
  fragment StakingRevenuePointFragment on StakingRevenuePoint {
    amount
    timestamp
  }
  """

  @staking_summary_fragment """
  fragment StakingSummaryFragment on StakingSummary {
    apr {
      ...AprFragment
    }
    apy {
      ...AprFragment
    }
    revenue7
  }
  #{@apr_fragment}
  """

  @staking_pool_fragment """
  fragment StakingPoolFragment on StakingPool {
    id
    address
    contract {
      ...ContractInfoFragment
    }
    bondAsset {
      ...AssetFragment
    }
    revenueAsset {
      ...AssetFragment
    }
    receiptAsset {
      ...AssetFragment
    }
    revenueConverter {
      ...RevenueConverterTypeFragment
    }
    status {
      ...StakingStatusFragment
    }
    summary {
      ...StakingSummaryFragment
    }
    deploymentStatus
  }
  #{@staking_status_fragment}
  #{@revenue_converter_type_fragment}
  #{@staking_summary_fragment}
  #{@asset_fragment}
  #{@contract_info_fragment}
  """

  @staking_account_fragment """
  fragment StakingAccountFragment on StakingAccount {
    id
    pool {
      id
      address
    }
    account
    bonded {
      ...BalanceFragment
    }
    liquid {
      ...BalanceFragment
    }
    liquidSize {
      ...BalanceFragment
    }
    liquidShares {
      ...BalanceFragment
    }
    pendingRevenue {
      ...BalanceFragment
    }
    valueUsd
  }
  #{@balance_fragment}
  """

  @staking_accounts_fragment """
  fragment StakingAccountsFragment on StakingAccounts {
    single {
      ...StakingAccountFragment
    }
    dual {
      ...StakingAccountFragment
    }
  }
  #{@staking_account_fragment}
  """

  def get_staking_status_fragment, do: @staking_status_fragment
  def get_revenue_converter_type_fragment, do: @revenue_converter_type_fragment
  def get_revenue_converter_fragment, do: @revenue_converter_fragment
  def get_staking_revenue_point_fragment, do: @staking_revenue_point_fragment
  def get_staking_summary_fragment, do: @staking_summary_fragment
  def get_staking_pool_fragment, do: @staking_pool_fragment
  def get_staking_account_fragment, do: @staking_account_fragment
  def get_staking_accounts_fragment, do: @staking_accounts_fragment
end
