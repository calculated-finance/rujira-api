defmodule RujiraWeb.Fragments.StrategyFragments do
  @moduledoc false
  import RujiraWeb.Fragments.BowFragments
  import RujiraWeb.Fragments.ThorchainFragments
  import RujiraWeb.Fragments.IndexFragments

  @strategy_account_fragment """
  fragment StrategyAccountFragment on StrategyAccount {
    ... on BowAccount {
      ...BowAccountFragment
    }
    ... on ThorchainLiquidityProvider {
      ...ThorchainLiquidityProviderFragment
    }
    ... on IndexAccount {
      ...IndexAccountFragment
    }
  }
  #{get_bow_account_fragment()}
  #{get_thorchain_liquidity_provider_fragment()}
  #{get_index_account_fragment()}
  """

  @strategy_fragment """
  fragment StrategyFragment on Strategy {
    ... on BowPoolXyk {
      ...BowPoolXykFragment
    }
    ... on ThorchainPool {
      ...ThorchainPoolFragment
    }
    ... on IndexVault {
      ...IndexVaultFragment
    }
  }
  #{get_bow_pool_xyk_fragment()}
  #{get_thorchain_pool_fragment()}
  #{get_index_vault_fragment()}
  """

  def get_strategy_account_fragment, do: @strategy_account_fragment
  def get_strategy_fragment, do: @strategy_fragment
end
