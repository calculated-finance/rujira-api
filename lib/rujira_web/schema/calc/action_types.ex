defmodule RujiraWeb.Schema.Calc.ActionTypes do
  @moduledoc """
  Defines GraphQL types for Calc Protocol data in the Rujira API.

  This module contains the type definitions and field resolvers for Calc Protocol
  GraphQL objects, including actions, and related data structures.
  """
  use Absinthe.Schema.Notation
  alias Rujira.Calc.Action

  object :calc_action do
    field :action, non_null(:calc_action_type)
    field :index, non_null(:integer)
    field :next, :integer
  end

  union :calc_action_type do
    types([:calc_action_swap, :calc_action_limit_order, :calc_action_distribute])

    resolve_type(fn
      %Action.Swap{}, _ -> :calc_action_swap
      %Action.LimitOrder{}, _ -> :calc_action_limit_order
      %Action.Distribute{}, _ -> :calc_action_distribute
    end)
  end

  object :calc_action_swap do
    field :test, :string
  end

  object :calc_action_limit_order do
    field :test, :string
  end

  object :calc_action_distribute do
    field :test, :string
  end
end
