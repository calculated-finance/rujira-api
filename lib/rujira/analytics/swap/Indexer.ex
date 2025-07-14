defmodule Rujira.Analytics.Swap.Indexer do
  @moduledoc """
  Listener for base layer swap events.
  """
  alias Rujira.Analytics.Swap
  alias Rujira.Prices
  alias Thorchain.Affiliates
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{header: %{time: time}, end_block_events: events}, state) do
    # returning the list of swaps weighted by affiliate bps
    swaps =
      events
      |> Enum.map(&scan_swap_event/1)
      |> Enum.reject(&is_nil/1)
      |> List.flatten()

    # Insert swap rows to all bins except affiliates
    # this avoid duplicate entries in the swap bins
    Swap.insert_address(swaps, time)
    Swap.insert_chain(swaps, time)
    Swap.insert_asset(swaps, time)
    Swap.insert_affiliate(swaps, time)

    {:noreply, state}
  end

  defp scan_swap_event(%{
         attributes: %{
           "pool" => pool,
           "liquidity_fee_in_rune" => liquidity_fee_in_rune,
           "emit_asset" => emit_asset,
           "chain" => chain,
           "from" => from,
           "coin" => coin,
           "memo" => memo
         },
         type: "swap"
       }) do
    insert_swap(pool, liquidity_fee_in_rune, emit_asset, chain, from, coin, memo)
  end

  defp scan_swap_event(_), do: nil

  defp insert_swap(
         pool,
         liquidity_fee_in_rune,
         emit_asset,
         chain,
         from,
         coin,
         memo
       ) do
    with {:ok, %{current: price}} <- Prices.get("RUNE"),
         liquidity_fee_in_rune <- String.to_integer(liquidity_fee_in_rune),
         coin <- parse_asset(coin),
         emit_asset <- parse_asset(emit_asset) do
      volume_usd =
        swap_size_rune(coin, emit_asset)
        |> Decimal.mult(price)
        |> Decimal.round()
        |> Decimal.to_integer()

      liquidity_fee_in_usd =
        liquidity_fee_in_rune
        |> Decimal.mult(price)
        |> Decimal.round()
        |> Decimal.to_integer()

      swap = %{
        asset: pool,
        source_chain: chain,
        address: from,
        volume: volume_usd,
        liquidity_fee: liquidity_fee_in_usd,
        total_swaps: 1
      }

      list_of_affiliate_data = affiliate_data(memo, volume_usd)

      merge_data(swap, list_of_affiliate_data)
    end
  end

  defp merge_data(swap, []) do
    [
      %{
        asset: swap.asset,
        source_chain: swap.source_chain,
        address: swap.address,
        address_weight: Decimal.new(1),
        volume: swap.volume,
        liquidity_fee: swap.liquidity_fee,
        count: Decimal.new(1),
        # no affiliate
        affiliate: "*",
        revenue: 0,
        bps: Decimal.new(0)
      }
    ]
  end

  defp merge_data(swap, list_of_affiliate_data) do
    # sum the total bps so that we can weight the data for the swap
    total_bps =
      Enum.reduce(list_of_affiliate_data, Decimal.new(0), fn affiliate_data, acc ->
        Decimal.add(acc, affiliate_data.bps)
      end)

    # weight the data for the swap
    Enum.map(list_of_affiliate_data, fn affiliate_data ->
      # if total bps is 0, set weight to 1/length(list_of_affiliate_data) to avoid division by zero
      weight =
        if total_bps == Decimal.new(0),
          do: Decimal.div(Decimal.new(1), Decimal.new(length(list_of_affiliate_data))),
          else: Decimal.div(affiliate_data.bps, total_bps)

      volume =
        swap.volume
        |> Decimal.new()
        |> Decimal.mult(weight)
        |> Decimal.round()
        |> Decimal.to_integer()

      liquidity_fee =
        swap.liquidity_fee
        |> Decimal.new()
        |> Decimal.mult(weight)
        |> Decimal.round()
        |> Decimal.to_integer()

      %{
        asset: swap.asset,
        source_chain: swap.source_chain,
        address: swap.address,
        address_weight: weight,
        volume: volume,
        liquidity_fee: liquidity_fee,
        count: weight,
        affiliate: affiliate_data.affiliate,
        revenue: affiliate_data.revenue,
        bps: affiliate_data.bps
      }
    end)
  end

  defp affiliate_data(memo, volume_usd) do
    case Affiliates.get_affiliate(memo) do
      {:ok, affiliates} ->
        Enum.map(affiliates, fn {aff, bps} ->
          revenue =
            volume_usd
            |> Decimal.mult(bps)
            |> Decimal.round()
            |> Decimal.to_integer()

          %{affiliate: aff, revenue: revenue, bps: bps}
        end)

      _ ->
        []
    end
  end

  defp parse_asset(asset_str) do
    case String.split(asset_str, " ", parts: 2) do
      [amount_str, asset] -> {asset, String.to_integer(amount_str)}
      _ -> {"", 0}
    end
  end

  defp swap_size_rune({"THOR.RUNE", in_amount}, _), do: in_amount
  defp swap_size_rune(_, {"THOR.RUNE", out_amount}), do: out_amount
  defp swap_size_rune(_, _), do: 0
end
