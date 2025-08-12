defmodule RujiraWeb.Fragments.GhostFragments do
  @moduledoc false
  alias RujiraWeb.Fragments.AssetFragments

  @asset_fragment AssetFragments.get_asset_fragment()

  @ghost_vault_interest_fragment """
  fragment GhostVaultInterestFragment on GhostVaultInterest {
    baseRate
    step1
    step2
    targetUtilization
  }
  """

  @ghost_vault_status_fragment """
  fragment GhostVaultStatusFragment on GhostVaultStatus {
    last_updated
    utilization_ratio
    debt_rate
    lend_rate
    debt_pool {
      size
      shares
      ratio
    }
    deposit_pool {
      size
      shares
      ratio
    }
  }
  """

  @ghost_vault_fragment """
  fragment GhostVaultFragment on GhostVault {
    id
    address
    asset {
      ...AssetFragment
    }
    interest {
      ...GhostVaultInterestFragment
    }
    status {
      ...GhostVaultStatusFragment
    }
  }
  #{@asset_fragment}
  #{@ghost_vault_interest_fragment}
  #{@ghost_vault_status_fragment}
  """

  def get_ghost_vault_fragment, do: @ghost_vault_fragment
end
