defmodule RujiraWeb.Schema.Calc.Action.SwapTypes do
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

  union :calc_swap_amount_adjustment_type do
    types([:calc_swap_amount_adjustment_fixed, :calc_swap_amount_adjustment_linear_scalar])

    resolve_type(fn
      %SwapAmountAdjustment.Fixed{}, _ -> :calc_swap_amount_adjustment_fixed
      %SwapAmountAdjustment.LinearScalar{}, _ -> :calc_swap_amount_adjustment_linear_scalar
    end)
  end

  object :calc_swap_amount_adjustment_fixed do
  end

  object :calc_swap_amount_adjustment_linear_scalar do
    field :base_receive_amount, non_null(:balance)
    field :minimum_swap_amount, non_null(:balance)
    field :scalar, non_null(:float)
  end
end
