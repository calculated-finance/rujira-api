defmodule Thorchain.Swaps.Indexer do
  alias Rujira.Prices
  alias Thorchain.Swaps
  alias Phoenix.PubSub
  use GenServer
  require Logger

  @impl true
  def init(opts) do
    PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")
    {:ok, opts}
  end

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def handle_info(
        %{
          header: %{height: height, time: time},
          txs: _txs,
          begin_block_events: _begin_events,
          end_block_events: events
        },
        state
      ) do
    index = 2_147_483_647
    scan_events(height, index, time, events)

    {:noreply, state}
  end

  defp scan_events(height, tx_idx, time, events) do
    swaps = Enum.flat_map(events, &scan_event(&1))
    IO.inspect(swaps)

    for {swap, idx} <- Enum.with_index(swaps) do
      swap
      |> Map.merge(%{
        height: height,
        tx_idx: tx_idx,
        idx: idx,
        timestamp: time
      })
      |> Swaps.insert_swap()
    end
  end

  defp scan_event(%{attributes: attributes, type: "swap"}) do
    IO.inspect(attributes)
    scan_attributes(attributes)
  end

  defp scan_event(_), do: []

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{value: pool, key: "pool"},
           %{value: _swap_target, key: "swap_target"},
           %{value: _swap_slip, key: "swap_slip"},
           %{value: _liquidity_fee, key: "liquidity_fee"},
           %{value: liquidity_fee_in_rune, key: "liquidity_fee_in_rune"},
           %{value: emit_asset, key: "emit_asset"},
           %{value: streaming_swap_quantity, key: "streaming_swap_quantity"},
           %{value: streaming_swap_count, key: "streaming_swap_count"},
           %{value: _pool_slip, key: "pool_slip"},
           %{value: id, key: "id"},
           %{value: chain, key: "chain"},
           %{value: from, key: "from"},
           %{value: to, key: "to"},
           %{value: coin, key: "coin"},
           %{value: memo, key: "memo"}
           | rest
         ],
         collection
       ) do
    scan_attributes(
      rest,
      insert_swap(
        collection,
        pool,
        liquidity_fee_in_rune,
        emit_asset,
        streaming_swap_quantity,
        streaming_swap_count,
        id,
        chain,
        from,
        to,
        coin,
        memo
      )
    )
  end

  defp scan_attributes([_ | rest], collection) do
    scan_attributes(rest, collection)
  end

  defp scan_attributes([], collection), do: collection

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

        %{
          affiliate: aff,
          affiliate_bps: bps,
          affiliate_fee_in_rune: affiliate_fee_in_rune,
          affiliate_fee_in_usd: affiliate_fee_in_usd
        }

      {:error, :no_affiliate} ->
        %{}
    end
  end

  defp insert_swap(
         collection,
         pool,
         liquidity_fee_in_rune,
         emit_asset,
         streaming_swap_quantity,
         streaming_swap_count,
         id,
         chain,
         from,
         to,
         coin,
         memo
       ) do
    with {:ok, %{price: price}} <- Prices.get("RUNE") do
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

      swap =
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

      [swap | collection]
    end
  end

  defp swap_size_rune({"THOR.RUNE", in_amount}, _), do: in_amount
  defp swap_size_rune(_, {"THOR.RUNE", out_amount}), do: out_amount
  defp swap_size_rune(_, _), do: 0
end
