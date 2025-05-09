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
    with {:ok, %{rune_price_in_tor: price}} <- Thorchain.network(),
         price <- String.to_integer(price) do
      index = 2_147_483_647
      scan_events(height, index, time, events, price)

      {:noreply, state}
    else
      {:error, _} ->
        {:noreply, state}
    end
  end

  defp scan_events(height, tx_idx, time, events, price) do
    swaps = Enum.flat_map(events, &scan_event(&1, price))

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

  defp scan_event(%{attributes: attributes}, price) do
    scan_attributes(attributes, price)
  end

  # API returns a list of attributes inside the list of events without key :attributes
  defp scan_event(attributes, price) when is_map(attributes) do
    scan_attributes(Rujira.convert_attributes(attributes), price)
  end

  defp scan_attributes(attributes, price, collection \\ [])

  defp scan_attributes(
         [
           %{value: chain, key: "chain"},
           %{value: coin, key: "coin"},
           %{value: emit_asset, key: "emit_asset"},
           %{value: from, key: "from"},
           %{value: id, key: "id"},
           %{value: _liquidity_fee, key: "liquidity_fee"},
           %{value: liquidity_fee_in_rune, key: "liquidity_fee_in_rune"},
           %{value: memo, key: "memo"},
           %{value: _mode, key: "mode"},
           %{value: pool, key: "pool"},
           %{value: _pool_slip, key: "pool_slip"},
           %{value: streaming_swap_count, key: "streaming_swap_count"},
           %{value: streaming_swap_quantity, key: "streaming_swap_quantity"},
           %{value: _swap_slip, key: "swap_slip"},
           %{value: _swap_target, key: "swap_target"},
           %{value: to, key: "to"}
           | rest
         ],
         price,
         collection
       ) do
    scan_attributes(
      rest,
      price,
      insert_swap(
        collection,
        price,
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

  defp scan_attributes([_ | rest], price, collection) do
    scan_attributes(rest, price, collection)
  end

  defp scan_attributes([], _, collection), do: collection

  defp get_affiliate_data(memo, price, volume_usd) do
    case Thorchain.get_affiliate(memo) do
      {:ok, {aff, bps}} ->
        affiliate_fee =
          Decimal.new(volume_usd) |> Decimal.mult(bps) |> Decimal.round() |> Decimal.to_integer()

        %{
          affiliate: aff,
          affiliate_bps: bps,
          affiliate_fee_in_rune: Prices.normalize(affiliate_fee / price, 4),
          affiliate_fee_in_usd: affiliate_fee
        }

      {:error, :no_affiliate} ->
        %{}
    end
  end

  defp insert_swap(
         collection,
         price,
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
    liquidity_fee_in_rune = String.to_integer(liquidity_fee_in_rune)
    liquidity_fee_in_usd = Prices.normalize(liquidity_fee_in_rune * price, 16)
    streaming_swap_quantity = String.to_integer(streaming_swap_quantity)
    streaming_swap_count = String.to_integer(streaming_swap_count)

    [coin_amount, coin_asset] = String.split(coin, " ", parts: 2)
    [emit_asset_amount, emit_asset_asset] = String.split(emit_asset, " ", parts: 2)
    coin_amount = String.to_integer(coin_amount)
    emit_asset_amount = String.to_integer(emit_asset_amount)

    volume_usd =
      cond do
        String.contains?(coin_asset, "THOR.RUNE") ->
          Prices.normalize(coin_amount * price, 16)

        String.contains?(emit_asset_asset, "THOR.RUNE") ->
          Prices.normalize(emit_asset_amount * price, 16)

        true ->
          0
      end

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
