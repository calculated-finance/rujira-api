defmodule RujiraWeb.Fragments.VestingFragments do
  @moduledoc false

  alias RujiraWeb.Fragments.BalanceFragments
  alias RujiraWeb.Fragments.DeveloperFragments

  @balance_fragment BalanceFragments.get_balance_fragment()
  @contract_info_fragment DeveloperFragments.get_contract_info_fragment()

  @vesting_vested_type_saturating_linear_fragment """
  fragment VestingVestedTypeSaturatingLinearFragment on VestingVestedTypeSaturatingLinear {
    type
    maxX
    maxY
    minX
    minY
  }
  """

  @vesting_fragment """
  fragment VestingFragment on Vesting {
    id
    address
    contract {
      ...ContractInfoFragment
    }
    creator
    recipient
    startTime
    vested {
      ...VestingVestedTypeSaturatingLinearFragment
    }
    total {
      ...BalanceFragment
    }
    claimed {
      ...BalanceFragment
    }
    slashed {
      ...BalanceFragment
    }
    remaining {
      ...BalanceFragment
    }
    status
    title
    description
  }
  #{@vesting_vested_type_saturating_linear_fragment}
  #{@contract_info_fragment}
  #{@balance_fragment}
  """

  @vesting_account_fragment """
  fragment VestingAccountFragment on VestingAccount {
    id
    address
    vestings {
      ...VestingFragment
    }
    valueUsd
  }
  #{@vesting_fragment}
  """

  def get_vesting_vested_type_saturating_linear_fragment,
    do: @vesting_vested_type_saturating_linear_fragment

  def get_vesting_fragment, do: @vesting_fragment
  def get_vesting_account_fragment, do: @vesting_account_fragment
end
