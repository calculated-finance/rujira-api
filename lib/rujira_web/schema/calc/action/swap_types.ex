defmodule RujiraWeb.Schema.Calc.Action.SwapTypes do
  @moduledoc """
  Defines GraphQL types for swap actions in Calc Protocol.

  This module contains type definitions for swap actions including amount adjustment
  strategies and the complete swap action type with all its parameters.
  """
  use Absinthe.Schema.Notation
  alias Rujira.Calc.Common.SwapAmountAdjustment

  import_types(RujiraWeb.Schema.Calc.Common.SwapRouteTypes)

  object :calc_action_swap do
    field :swap_amount, non_null(:balance)
    field :minimum_receive_amount, non_null(:balance)
    field :maximum_slippage_bps, non_null(:integer)
    field :adjustment, non_null(:calc_swap_amount_adjustment_type)
    field :routes, non_null(list_of(non_null(:calc_swap_route_type)))
  end

  enum :swap_amount_adjustment_kind do
    value(:fixed)
    value(:linear_scalar)
  end

  union :calc_swap_amount_adjustment_type do
    types([:calc_swap_amount_adjustment_fixed, :calc_swap_amount_adjustment_linear_scalar])

    resolve_type(fn
      %SwapAmountAdjustment.Fixed{}, _ -> :calc_swap_amount_adjustment_fixed
      %SwapAmountAdjustment.LinearScalar{}, _ -> :calc_swap_amount_adjustment_linear_scalar
    end)
  end

  object :calc_swap_amount_adjustment_fixed do
    field :kind, non_null(:swap_amount_adjustment_kind), resolve: fn _, _, _ -> {:ok, :fixed} end
  end

  object :calc_swap_amount_adjustment_linear_scalar do
    field :kind, non_null(:swap_amount_adjustment_kind), resolve: fn _, _, _ -> {:ok, :linear_scalar} end
    field :base_receive_amount, non_null(:balance)
    field :minimum_swap_amount, non_null(:balance)
    field :scalar, non_null(:float)
  end
end
