defmodule RujiraWeb.Schema.Calc.Common.SwapRouteTypes do
  @moduledoc """
  Defines GraphQL types for swap routing data in Calc actions.

  This module contains type definitions for different swap route types including
  Fin and Thorchain routes with their respective configuration parameters.
  """
  use Absinthe.Schema.Notation
  alias Rujira.Calc.Common.SwapRoute

  union :calc_swap_route_type do
    types([:calc_swap_route_fin, :calc_swap_route_thorchain])

    resolve_type(fn
      %SwapRoute.Fin{}, _ -> :calc_swap_route_fin
      %SwapRoute.Thorchain{}, _ -> :calc_swap_route_thorchain
    end)
  end

  object :calc_swap_route_fin do
    field :pair_address, non_null(:address)
  end

  object :calc_swap_route_thorchain do
    field :streaming_interval, :integer
    field :max_streaming_quantity, :integer
    field :affiliate_code, :string
    field :affiliate_bps, :integer
    field :latest_swap, :calc_thorchain_streaming_swap
  end

  object :calc_thorchain_streaming_swap do
    field :swap_amount, non_null(:balance)
    field :expected_receive_amount, non_null(:balance)
    field :starting_block, non_null(:integer)
    field :streaming_swap_blocks, non_null(:integer)
    field :memo, non_null(:string)
  end
end