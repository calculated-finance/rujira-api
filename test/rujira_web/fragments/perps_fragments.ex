defmodule RujiraWeb.Fragments.PerpsFragments do
  @moduledoc false

  alias RujiraWeb.Fragments.AssetFragments
  alias RujiraWeb.Fragments.BalanceFragments
  alias RujiraWeb.Fragments.DeveloperFragments

  @asset_fragment AssetFragments.get_asset_fragment()
  @balance_fragment BalanceFragments.get_balance_fragment()
  @contract_info_fragment DeveloperFragments.get_contract_info_fragment()

  @liquidity_cooldown_fragment """
  fragment LiquidityCooldownFragment on PerpsLiquidityCooldown {
    startAt
    endAt
  }
  """

  @perps_stats_fragment """
  fragment PerpsStatsFragment on PerpsStats {
    sharpeRatio
    lpApr
    xlpApr
    risk
  }
  """

  @perps_liquidity_fragment """
  fragment PerpsLiquidityFragment on PerpsLiquidity {
    total {
      ...BalanceFragment
    }
    unlocked {
      ...BalanceFragment
    }
    locked {
      ...BalanceFragment
    }
  }
  #{@balance_fragment}
  """

  @perps_pool_fragment """
  fragment PerpsPoolFragment on PerpsPool {
    id
    address
    contract {
      ...ContractInfoFragment
    }
    name
    baseAsset {
      ...AssetFragment
    }
    quoteAsset {
      ...AssetFragment
    }
    liquidity {
      ...PerpsLiquidityFragment
    }
    stats {
      ...PerpsStatsFragment
    }
  }
  #{@perps_liquidity_fragment}
  #{@perps_stats_fragment}
  #{@asset_fragment}
  #{@contract_info_fragment}
  """

  @perps_account_fragment """
  fragment PerpsAccountFragment on PerpsAccount {
    id
    account
    pool {
      id
      address
    }
    lpShares
    valueUsd
    lpSize {
      ...BalanceFragment
    }
    xlpShares
    xlpSize {
      ...BalanceFragment
    }
    availableYieldLp {
      ...BalanceFragment
    }
    availableYieldXlp {
      ...BalanceFragment
    }
    liquidityCooldown {
      ...LiquidityCooldownFragment
    }
  }
  #{@balance_fragment}
  #{@asset_fragment}
  #{@liquidity_cooldown_fragment}
  """

  def get_perps_stats_fragment, do: @perps_stats_fragment
  def get_perps_liquidity_fragment, do: @perps_liquidity_fragment
  def get_perps_pool_fragment, do: @perps_pool_fragment
  def get_perps_account_fragment, do: @perps_account_fragment
end
