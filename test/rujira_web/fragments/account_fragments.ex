defmodule RujiraWeb.Fragments.AccountFragments do
  import RujiraWeb.Fragments.BowFragments
  import RujiraWeb.Fragments.FinFragments
  import RujiraWeb.Fragments.StakingFragments
  import RujiraWeb.Fragments.StrategyFragments
  import RujiraWeb.Fragments.BalanceFragments
  import RujiraWeb.Fragments.ThorchainFragments

  @account_fragment """
  fragment AccountFragment on Account {
    id
    address
    bow {
      ...BowAccountFragment
    }
    fin {
      ...FinAccountFragment
    }
    staking {
      ...StakingAccountsFragment
    }
    staking_v2 {
      ...StakingAccountFragment
    }
    strategies {
      ...StrategyAccountFragment
    }
  }
  #{get_bow_account_fragment()}
  #{get_fin_account_fragment()}
  #{get_staking_accounts_fragment()}
  #{get_staking_account_fragment()}
  #{get_strategy_account_fragment()}
  """

  @layer1_account_fragment """
  fragment Layer1AccountFragment on Layer1Account {
    id
    address
    chain
    balances {
      ...Layer1BalanceFragment
    }
    account {
      ...AccountFragment
    }
    liquidityAccounts {
      ...ThorchainLiquidityProviderFragment
    }
  }
  #{@account_fragment}
  #{get_layer1_balance_fragment()}
  #{get_thorchain_liquidity_provider_fragment()}
  """

  def get_layer1_account_fragment(), do: @layer1_account_fragment
  def get_account_fragment(), do: @account_fragment
end
