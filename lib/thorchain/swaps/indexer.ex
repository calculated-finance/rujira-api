defmodule Thorchain.Swaps.Indexer do
  @moduledoc """
  Indexer module for tracking and processing Thorchain swaps.

  This module implements the Thornode.Observer behaviour to monitor new blocks
  and process swap events from the Thorchain network.
  """

  alias Rujira.Prices
  alias Thorchain.Swaps
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(
        %{
          header: %{height: height, time: time},
          txs: _txs,
          begin_block_events: _begin_events,
          end_block_events: events
        },
        state
      ) do
    events
    |> Enum.map(&scan_swap/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.with_index()
    |> Enum.each(fn {swap, idx} ->
      Map.merge(swap, %{
        height: height,
        tx_idx: 2_147_483_647,
        idx: idx,
        timestamp: time
      })
      |> Swaps.insert_swap()
    end)

    {:noreply, state}
  end

  defp scan_swap(%{
         attributes: %{
           "pool" => pool,
           "liquidity_fee_in_rune" => liquidity_fee_in_rune,
           "emit_asset" => emit_asset,
           "streaming_swap_quantity" => streaming_swap_quantity,
           "streaming_swap_count" => streaming_swap_count,
           "id" => id,
           "chain" => chain,
           "from" => from,
           "to" => to,
           "coin" => coin,
           "memo" => memo
         },
         type: "swap"
       }) do
    parse_swap(%{
      pool: pool,
      liquidity_fee_in_rune: liquidity_fee_in_rune,
      emit_asset: emit_asset,
      streaming_swap_quantity: streaming_swap_quantity,
      streaming_swap_count: streaming_swap_count,
      id: id,
      chain: chain,
      from: from,
      to: to,
      coin: coin,
      memo: memo
    })
  end

  defp scan_swap(_), do: nil

  defp get_affiliate_data(memo, price, volume_usd) do
    case Thorchain.get_affiliate(memo) do
      {:ok, {aff, bps}} ->
        affiliate_fee_in_usd =
          volume_usd
          |> Decimal.mult(bps)
          |> Decimal.round()
          |> Decimal.to_integer()

        affiliate_fee_in_rune =
          affiliate_fee_in_usd
          |> Decimal.div(price)
          |> Decimal.round()
          |> Decimal.to_integer()

        bps =
          bps
          |> Decimal.div(10_000)
          |> Decimal.round()
          |> Decimal.to_integer()

        %{
          affiliate: aff,
          affiliate_bps: bps,
          affiliate_fee_in_rune: affiliate_fee_in_rune,
          affiliate_fee_in_usd: affiliate_fee_in_usd
        }

      _ ->
        %{}
    end
  end

  defp parse_swap(%{
         pool: pool,
         liquidity_fee_in_rune: liquidity_fee_in_rune,
         emit_asset: emit_asset,
         streaming_swap_quantity: streaming_swap_quantity,
         streaming_swap_count: streaming_swap_count,
         id: id,
         chain: chain,
         from: from,
         to: to,
         coin: coin,
         memo: memo
       }) do
    with {:ok, %{current: price}} <- Prices.get("RUNE") do
      liquidity_fee_in_rune = String.to_integer(liquidity_fee_in_rune)
      streaming_swap_quantity = String.to_integer(streaming_swap_quantity)
      streaming_swap_count = String.to_integer(streaming_swap_count)

      [coin_amount, coin_asset] = String.split(coin, " ", parts: 2)
      [emit_asset_amount, emit_asset_asset] = String.split(emit_asset, " ", parts: 2)
      coin_amount = String.to_integer(coin_amount)
      emit_asset_amount = String.to_integer(emit_asset_amount)

      liquidity_fee_in_usd =
        liquidity_fee_in_rune
        |> Decimal.mult(price)
        |> Decimal.round()
        |> Decimal.to_integer()

      volume_usd =
        swap_size_rune({coin_asset, coin_amount}, {emit_asset_asset, emit_asset_amount})
        |> Decimal.mult(price)
        |> Decimal.round()
        |> Decimal.to_integer()

      %{
        pool: pool,
        liquidity_fee_in_rune: liquidity_fee_in_rune,
        emit_asset_asset: emit_asset_asset,
        emit_asset_amount: emit_asset_amount,
        streaming_swap_quantity: streaming_swap_quantity,
        streaming_swap_count: streaming_swap_count,
        id: id,
        chain: chain,
        from: from,
        to: to,
        coin_asset: coin_asset,
        coin_amount: coin_amount,
        memo: memo,
        volume_usd: volume_usd,
        liquidity_fee_in_usd: liquidity_fee_in_usd
      }
      |> Map.merge(get_affiliate_data(memo, price, volume_usd))
    end
  end

  defp swap_size_rune({"THOR.RUNE", in_amount}, _), do: in_amount
  defp swap_size_rune(_, {"THOR.RUNE", out_amount}), do: out_amount
  defp swap_size_rune(_, _), do: 0
end
