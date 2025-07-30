defmodule Rujira.Analytics.Swap.Indexer do
  @moduledoc """
  Listener for base layer swap events.
  """
  alias Rujira.Analytics.Swap
  alias Rujira.Assets
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

    affiliate =
      events
      |> Enum.map(&scan_affiliate_event/1)
      |> Enum.reject(&is_nil/1)
      |> List.flatten()
      |> Enum.group_by(& &1.affiliate)
      |> Enum.map(fn {affiliate, entries} ->
        %{affiliate: affiliate, revenue: entries |> Enum.map(& &1.revenue) |> Enum.sum()}
      end)

    Swap.update_affiliate(affiliate, time)

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

  defp scan_affiliate_event(%{
         attributes: %{
           "thorname" => thorname,
           "asset" => asset,
           "fee_amount" => fee_amount
         },
         type: "affiliate_fee"
       }) do
    asset = Assets.from_string(asset)

    %{
      affiliate: thorname,
      revenue: Prices.value_usd(asset.symbol, fee_amount)
    }
  end

  defp scan_affiliate_event(_), do: nil

  defp insert_swap(
         pool,
         liquidity_fee_in_rune,
         emit_asset,
         chain,
         from,
         coin,
         memo
       ) do
    with liquidity_fee_in_rune <- String.to_integer(liquidity_fee_in_rune),
         coin <- parse_asset(coin),
         emit_asset <- parse_asset(emit_asset),
         chain <- parse_chain(chain, emit_asset, coin) do
      volume_usd = Prices.value_usd("RUNE", swap_size_rune(coin, emit_asset))
      liquidity_fee_in_usd = Prices.value_usd("RUNE", liquidity_fee_in_rune)

      swap = %{
        asset: pool,
        source_chain: chain,
        address: from,
        volume: volume_usd,
        liquidity_fee: liquidity_fee_in_usd,
        total_swaps: 1
      }

      merge_data(swap, affiliate_data(memo))
    end
  end

  defp merge_data(swap, []) do
    [base_swap_entry(swap, "*", Decimal.new(1), swap.volume, swap.liquidity_fee, Decimal.new(0))]
  end

  defp merge_data(swap, list_of_affiliate_data) do
    # sum the total bps so that we can weight the data for the swap
    total_bps =
      Enum.reduce(list_of_affiliate_data, Decimal.new(0), fn {_, bps}, acc ->
        Decimal.add(acc, bps)
      end)

    # weight the data for the swap
    Enum.map(list_of_affiliate_data, fn {affiliate, bps} ->
      # if total bps is 0, set weight to 1/length(list_of_affiliate_data) to avoid division by zero
      weight =
        case Decimal.compare(total_bps, 0) do
          :eq -> Decimal.div(1, length(list_of_affiliate_data))
          _ -> Decimal.div(bps, total_bps)
        end

      volume = weighted_amount(swap.volume, weight)
      liquidity_fee = weighted_amount(swap.liquidity_fee, weight)

      base_swap_entry(swap, affiliate, weight, volume, liquidity_fee, bps)
    end)
  end

  defp affiliate_data(memo) do
    case Affiliates.get_affiliate(memo) do
      {:ok, affiliates} -> affiliates
      _ -> []
    end
  end

  defp parse_asset(asset_str) do
    case String.split(asset_str, " ", parts: 2) do
      [amount_str, asset] -> {asset, String.to_integer(amount_str)}
      _ -> {"", 0}
    end
  end

  defp swap_size_rune(coin, emit_asset) do
    case {coin, emit_asset} do
      {{"THOR.RUNE", amount}, _} -> amount
      {_, {"THOR.RUNE", amount}} -> amount
      _ -> 0
    end
  end

  defp weighted_amount(amount, weight) do
    amount
    |> Decimal.new()
    |> Decimal.mult(weight)
    |> Decimal.round()
    |> Decimal.to_integer()
  end

  defp base_swap_entry(swap, affiliate, address_weight, volume, liquidity_fee, bps) do
    %{
      asset: swap.asset,
      source_chain: swap.source_chain,
      address: swap.address,
      address_weight: address_weight,
      volume: volume,
      liquidity_fee: liquidity_fee,
      count: address_weight,
      affiliate: affiliate,
      revenue: 0,
      bps: bps
    }
  end

  defp parse_chain("THOR", _, _), do: "THOR"

  defp parse_chain(chain, {emit_asset, _}, {coin, _}) do
    with %{chain: emit_chain} <- Assets.from_string(emit_asset),
         %{chain: coin_chain} <- Assets.from_string(coin) do
      if emit_chain != "THOR", do: emit_chain, else: coin_chain
    else
      _ -> chain
    end
  end
end
