defmodule RujiraWeb.Schema.CosmosTypes do
  @moduledoc """
  Defines GraphQL types for Cosmos Account data in the Rujira API.
  """
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias RujiraWeb.Resolvers

  node object(:cosmos_account) do
    field :chain, non_null(:chain)
    field :address, non_null(:address)

    field :staking, list_of(non_null(:cosmos_staking_account)) do
      resolve(&Resolvers.Cosmos.staking/3)
    end

    field :unbonding, list_of(non_null(:cosmos_unbonding_account)) do
      resolve(&Resolvers.Cosmos.unbonding/3)
    end

    field :vesting, :cosmos_vesting_account do
      resolve(&Resolvers.Cosmos.vesting_account/3)
    end
  end

  object :cosmos_staking_account do
    field :delegation, non_null(list_of(non_null(:cosmos_delegation_entry)))
    field :balance, non_null(:balance)
  end

  object :cosmos_delegation_entry do
    field :delegator_address, non_null(:string)
    field :validator_address, non_null(:string)
    field :shares, non_null(:bigint)
  end

  object :cosmos_unbonding_account do
    field :delegator_address, non_null(:string)
    field :validator_address, non_null(:string)
    field :entries, non_null(list_of(non_null(:cosmos_unbonding_entry)))
  end

  object :cosmos_unbonding_entry do
    field :creation_height, non_null(:bigint)
    field :completion_time, non_null(:timestamp)
    field :initial_balance, non_null(:bigint)
    field :balance, non_null(:balance)
  end

  object :cosmos_vesting_account do
    field :start_time, non_null(:timestamp)
    field :vesting_periods, non_null(list_of(non_null(:cosmos_vesting_period)))
  end

  object :cosmos_vesting_period do
    field :end_time, non_null(:timestamp)
    field :balances, list_of(non_null(:balance))
  end
end
