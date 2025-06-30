defmodule Thorchain.Swapper do
  @moduledoc """
  THORChain swap calculations with liquidity fees and slippage protection.

  This module provides functions to calculate asset emissions, liquidity fees, and swap slippage
  for THORChain pools
  """

  @max_basis_points 10_000
  @min_slip_bps 10

  @doc """
  Calculate the number of assets sent to the address (includes liquidity fee).
  Formula: (x * X * Y) / (x + X)^2
  """
  @spec calc_asset_emission(integer(), {integer(), integer()}) :: integer()
  def calc_asset_emission(0, _), do: 0
  def calc_asset_emission(_, {0, _}), do: 0
  def calc_asset_emission(input, {x, y}), do: div(x * input * y, (x + input) * (x + input))

  @doc """
  Calculate the asset amount to be sent to address using a predefined fee.
  Formula: ((x * Y) / (x + X)) - fee
  """
  @spec calc_max_asset_emission(integer(), {integer(), integer()}, integer()) :: integer()
  def calc_max_asset_emission(0, _), do: 0
  def calc_max_asset_emission(_, {0, _}), do: 0
  # Ensure non-negative result
  def calc_max_asset_emission(input, {x, y}, fee), do: max(0, div(input * y, x + input) - fee)

  @doc """
  Calculate the liquidity fee of the swap.
  Formula: (x^2 * Y) / (x + X)^2
  """
  @spec calc_liquidity_fee(integer(), {integer(), integer()}) :: integer()
  def calc_liquidity_fee(0, _), do: 0
  def calc_liquidity_fee(_, {0, _}), do: 0
  def calc_liquidity_fee(input, {x, y}), do: div(input * input * y, (x + input) * (x + input))

  @doc """
  Calculate the minimum liquidity fee using artificial slip floor.
  Formula: minSlip * (x * Y) / (x + X)
  """
  @spec calc_min_liquidity_fee(integer(), {integer(), integer()}, integer()) :: integer()
  def calc_min_liquidity_fee(input, pool, min_slip_bps \\ @min_slip_bps)
  def calc_min_liquidity_fee(0, _, _), do: 0
  def calc_min_liquidity_fee(_, {0, _}, _), do: 0

  def calc_min_liquidity_fee(input, {x, y}, min_slip_bps),
    do: div(get_safe_share(min_slip_bps, @max_basis_points, input * y), x + input)

  @doc """
  Calculate swap slippage expressed in basis points (10000 = 100%).
  Formula: x / (x + X) * 10000
  """
  @spec calc_swap_slip(integer(), {integer(), integer()}) :: integer()
  def calc_swap_slip(0, _), do: 0
  def calc_swap_slip(_, {0, _}), do: 0

  def calc_swap_slip(input, {x, _}),
    do: round(input * @max_basis_points / (x + input))

  @doc """
  Calculate the maximum input that achieves the minimum slip in basis points.
  Formula: (min_slip_bps * X) / (10000 - min_slip_bps)
  """
  @spec calc_max_input({integer(), integer()}, integer()) :: integer()
  def calc_max_input(pool, min_slip_bps \\ @min_slip_bps)
  def calc_max_input({0, _}, _), do: 0

  def calc_max_input({x, _}, min_slip_bps),
    do: div(min_slip_bps * x, @max_basis_points - min_slip_bps)

  @doc """
  Get comprehensive swap calculation results.
  Returns {emit_assets, liquidity_fee, slip} tuple.
  """
  @spec get_swap_calc(integer(), {integer(), integer()}, integer(), integer()) ::
          {integer(), integer(), integer()}
  def get_swap_calc(input, pool, slip_bps, min_slip_bps \\ @min_slip_bps)

  def get_swap_calc(input, pool, slip_bps, min_slip_bps) when min_slip_bps > slip_bps do
    # Use artificial floor
    liquidity_fee = calc_min_liquidity_fee(input, pool, min_slip_bps)
    emit_assets = calc_max_asset_emission(input, pool, liquidity_fee)
    {emit_assets, liquidity_fee, min_slip_bps}
  end

  def get_swap_calc(input, pool, slip_bps, _) do
    # Use natural slippage
    liquidity_fee = calc_liquidity_fee(input, pool)
    emit_assets = calc_asset_emission(input, pool)
    {emit_assets, liquidity_fee, slip_bps}
  end

  @doc """
  Process a complete swap calculation including pool slip calculation.
  """
  @spec process_swap(integer(), {integer(), integer()}, integer()) ::
          %{
            emit_assets: integer(),
            liquidity_fee: integer(),
            pool_slip: integer(),
            swap_slip: integer()
          }
  def process_swap(input, pool, min_slip_bps \\ @min_slip_bps) do
    # Calculate pool slip
    pool_slip_bps = calc_swap_slip(input, pool)
    # Get swap calculations
    {emit_assets, liquidity_fee, swap_slip} =
      get_swap_calc(input, pool, pool_slip_bps, min_slip_bps)

    %{
      emit_assets: emit_assets,
      liquidity_fee: liquidity_fee,
      pool_slip: pool_slip_bps,
      swap_slip: swap_slip
    }
  end

  defp get_safe_share(part, total, amount) when total > 0, do: div(part * amount, total)
  defp get_safe_share(_part, _total, _amount), do: 0
end
