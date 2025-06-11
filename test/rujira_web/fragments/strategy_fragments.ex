defmodule RujiraWeb.Fragments.StrategyFragments do
  import RujiraWeb.Fragments.BowFragments
  import RujiraWeb.Fragments.ThorchainFragments

  @strategy_account_fragment """
  fragment StrategyAccountFragment on StrategyAccount {
    ... on BowAccount {
      ...BowAccountFragment
    }
    ... on ThorchainLiquidityProvider {
      ...ThorchainLiquidityProviderFragment
    }
  }
  #{get_bow_account_fragment()}
  #{get_thorchain_liquidity_provider_fragment()}
  """

  @strategy_fragment """
  fragment StrategyFragment on Strategy {
    ... on BowPoolXyk {
      ...BowPoolXykFragment
    }
    ... on ThorchainPool {
      ...ThorchainPoolFragment
    }
  }
  #{get_bow_pool_xyk_fragment()}
  #{get_thorchain_pool_fragment()}
  """


  def get_strategy_account_fragment(), do: @strategy_account_fragment
  def get_strategy_fragment(), do: @strategy_fragment
end
