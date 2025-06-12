defmodule RujiraWeb.Fragments.IndexFragments do
  alias RujiraWeb.Fragments.AssetFragments
  alias RujiraWeb.Fragments.DeveloperFragments

  @asset_fragment AssetFragments.get_asset_fragment()
  @contract_info_fragment DeveloperFragments.get_contract_info_fragment()

  @index_config_fragment """
  fragment IndexConfigFragment on IndexConfig {
    feeCollector
    quoteAsset {
      ...AssetFragment
    }
  }
  #{@asset_fragment}
  """

  @index_allocation_fragment """
  fragment IndexAllocationFragment on IndexAllocation {
    asset {
      ...AssetFragment
    }
    targetWeight
    currentWeight
    balance
    value
    price
  }
  #{@asset_fragment}
  """

  @index_status_fragment """
  fragment IndexStatusFragment on IndexStatus {
    totalShares
    nav
    allocations {
      ...IndexAllocationFragment
    }
    totalValue
    navChange
  }
  #{@index_allocation_fragment}
  """

  @index_nav_bin_fragment """
  fragment IndexNavBinFragment on IndexNavBin {
    bin
    contract
    resolution
    open
  }
  """

  @index_vault_fragment """
  fragment IndexVaultFragment on IndexVault {
    id
    address
    contract {
      ...ContractInfoFragment
    }
    type
    entryAdapter
    config {
      ...IndexConfigFragment
    }
    status {
      ...IndexStatusFragment
    }
    shareAsset {
      ...AssetFragment
    }
  }
  #{@contract_info_fragment}
  #{@asset_fragment}
  #{@index_config_fragment}
  #{@index_status_fragment}
  """

  @index_account_fragment """
  fragment IndexAccountFragment on IndexAccount {
    id
    account
    index {
      ...IndexVaultFragment
    }
    shares
    sharesValue
  }
  #{@index_vault_fragment}
  """

  def get_index_config_fragment(), do: @index_config_fragment
  def get_index_allocation_fragment(), do: @index_allocation_fragment
  def get_index_status_fragment(), do: @index_status_fragment
  def get_index_nav_bin_fragment(), do: @index_nav_bin_fragment
  def get_index_account_fragment(), do: @index_account_fragment
  def get_index_vault_fragment(), do: @index_vault_fragment
end
