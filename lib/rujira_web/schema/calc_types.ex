defmodule RujiraWeb.Schema.CalcTypes do
  @moduledoc """
  Defines GraphQL types for Calc Protocol data in the Rujira API.

  This module contains the type definitions and field resolvers for Calc Protocol
  GraphQL objects, including strategies, positions, and related data structures.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Rujira.Assets
  alias Rujira.Calc.Action
  alias Rujira.Calc.Condition
  alias Rujira.Contracts
  alias Rujira.Prices
  alias RujiraWeb.Resolvers.Calc

  # import types
  import_types(RujiraWeb.Schema.Calc.ActionTypes)
  import_types(RujiraWeb.Schema.Calc.ConditionTypes)

  node object(:calc_account) do
    field :address, non_null(:address)
    field :strategies, list_of(non_null(:calc_strategy))

    field :value_usd, non_null(:bigint) do
      resolve(fn %{strategies: calc_strategies}, _, _ ->
        {:ok, Calc.value_usd(calc_strategies)}
      end)
    end
  end

  connection(node_type: :calc_account)

  @desc "A strategy represents the configuration about a rujira-calc contract"
  node object(:calc_strategy) do
    field :idx, non_null(:integer)
    field :source, :address
    field :owner, non_null(:address)
    field :address, non_null(:address)
    field :created_at, non_null(:timestamp)
    field :updated_at, non_null(:timestamp)
    field :label, non_null(:string)
    field :status, non_null(:strategy_status)

    field :contract, non_null(:contract_info) do
      resolve(fn %{address: address}, _, _ ->
        Contracts.info(address)
      end)
    end

    field :config, non_null(:strategy_config)
  end

  enum :strategy_status do
    value(:active)
    value(:paused)
  end

  object :strategy_config do
    field :manager, non_null(:address)
    field :owner, non_null(:address)
    field :nodes, list_of(non_null(:calc_node))
  end

  union :calc_node do
    types([:calc_action, :calc_condition])

    resolve_type(fn
      %Action{}, _ -> :calc_action
      %Condition{}, _ -> :calc_condition
    end)
  end
end
