defmodule Rujira.Calc.Action.Swap do
  @moduledoc """
  Action type for executing token swaps between different denominations.
  """
  alias Rujira.Assets.Coin
  alias Rujira.Calc.Common.SwapAmountAdjustment
  alias Rujira.Calc.Common.SwapRoute

  defstruct [
    swap_amount: Coin.default(),
    minimum_receive_amount: Coin.default(),
    maximum_slippage_bps: 0,
    adjustment: SwapAmountAdjustment.default(),
    routes: []
  ]

  def from_config(%{
        "swap_amount" => swap_amount,
        "minimum_receive_amount" => minimum_receive_amount,
        "maximum_slippage_bps" => maximum_slippage_bps,
        "adjustment" => adjustment,
        "routes" => routes
      }) do
    with {:ok, swap_amount} <- Coin.parse(swap_amount),
         {:ok, minimum_receive_amount} <- Coin.parse(minimum_receive_amount),
         {:ok, adjustment} <- SwapAmountAdjustment.from_config(adjustment),
         {:ok, routes} <- Rujira.Enum.reduce_while_ok(routes, &SwapRoute.from_config/1) do
      {:ok,
       %__MODULE__{
         swap_amount: swap_amount,
         minimum_receive_amount: minimum_receive_amount,
         maximum_slippage_bps: maximum_slippage_bps,
         adjustment: adjustment,
         routes: routes
       }}
    end
  end
end
