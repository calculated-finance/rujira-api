defmodule RujiraWeb.Fragments.GhostFragments do
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

  @ghost_registry_fragment """
  fragment GhostRegistryFragment on GhostRegistry {
    codeId
    checksum
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
    registry {
      ...GhostRegistryFragment
    }
  }
  #{@asset_fragment}
  #{@ghost_vault_interest_fragment}
  #{@ghost_registry_fragment}
  """

  def get_ghost_vault_fragment(), do: @ghost_vault_fragment
end
