defmodule RujiraWeb.Fragments.CosmosFragments do
  @moduledoc false
  alias RujiraWeb.Fragments.BalanceFragments

  @balance_fragment BalanceFragments.get_balance_fragment()

  @cosmos_delegation_entry_fragment """
  fragment CosmosDelegationEntryFragment on CosmosDelegationEntry {
    delegatorAddress
    validatorAddress
    shares
  }
  """

  @cosmos_staking_account_fragment """
  fragment CosmosStakingAccountFragment on CosmosStakingAccount {
    delegation {
      ...CosmosDelegationEntryFragment
    }
    balance{
      ...BalanceFragment
    }
  }
  #{@cosmos_delegation_entry_fragment}
  #{@balance_fragment}
  """

  @cosmos_unbonding_entry_fragment """
  fragment CosmosUnbondingEntryFragment on CosmosUnbondingEntry {
    creationHeight
    completionTime
    initialBalance
    balance {
      ...BalanceFragment
    }
  }
  #{@balance_fragment}
  """

  @cosmos_unbonding_account_fragment """
  fragment CosmosUnbondingAccountFragment on CosmosUnbondingAccount {
    delegatorAddress
    validatorAddress
    entries {
      ...CosmosUnbondingEntryFragment
    }
  }
  #{@cosmos_unbonding_entry_fragment}
  """

  @cosmos_vesting_period_fragment """
  fragment CosmosVestingPeriodFragment on CosmosVestingPeriod {
    endTime
    balances {
      ...BalanceFragment
    }
  }
  #{@balance_fragment}
  """

  @cosmos_vesting_account_fragment """
  fragment CosmosVestingAccountFragment on CosmosVestingAccount {
    startTime
    vestingPeriods {
      ...CosmosVestingPeriodFragment
    }
  }
  #{@cosmos_vesting_period_fragment}
  """

  @cosmos_account_fragment """
  fragment CosmosAccountFragment on CosmosAccount {
    id
    chain
    address
    staking {
      ...CosmosStakingAccountFragment
    }
    unbonding {
      ...CosmosUnbondingAccountFragment
    }
    vesting {
      ...CosmosVestingAccountFragment
    }
  }
  #{@cosmos_staking_account_fragment}
  #{@cosmos_unbonding_account_fragment}
  #{@cosmos_vesting_account_fragment}
  """

  def get_cosmos_account_fragment, do: @cosmos_account_fragment
  def get_cosmos_staking_account_fragment, do: @cosmos_staking_account_fragment
  def get_cosmos_unbonding_account_fragment, do: @cosmos_unbonding_account_fragment
  def get_cosmos_vesting_account_fragment, do: @cosmos_vesting_account_fragment
  def get_cosmos_delegation_entry_fragment, do: @cosmos_delegation_entry_fragment
  def get_cosmos_unbonding_entry_fragment, do: @cosmos_unbonding_entry_fragment
  def get_cosmos_vesting_period_fragment, do: @cosmos_vesting_period_fragment
end
