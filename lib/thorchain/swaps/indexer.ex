defmodule Thorchain.Swaps.Indexer do
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
    swaps = Enum.flat_map(events, &scan_event/1)

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

  defp scan_event(%{attributes: attributes}) do
    scan_attributes(attributes)
  end

  # API returns a list of attributes inside the list of events without key :attributes
  defp scan_event(attributes) when is_map(attributes) do
    scan_attributes(Rujira.convert_attributes(attributes))
  end

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{value: chain, key: "chain"},
           %{value: coin, key: "coin"},
           %{value: emit_asset, key: "emit_asset"},
           %{value: from, key: "from"},
           %{value: id, key: "id"},
           %{value: liquidity_fee, key: "liquidity_fee"},
           %{value: liquidity_fee_in_rune, key: "liquidity_fee_in_rune"},
           %{value: memo, key: "memo"},
           %{value: _mode, key: "mode"},
           %{value: pool, key: "pool"},
           %{value: pool_slip, key: "pool_slip"},
           %{value: streaming_swap_count, key: "streaming_swap_count"},
           %{value: streaming_swap_quantity, key: "streaming_swap_quantity"},
           %{value: swap_slip, key: "swap_slip"},
           %{value: swap_target, key: "swap_target"},
           %{value: to, key: "to"}
           | rest
         ],
         collection
       ) do
    scan_attributes(
      rest,
      insert_swap(
        collection,
        pool,
        swap_slip,
        swap_target,
        liquidity_fee,
        liquidity_fee_in_rune,
        emit_asset,
        streaming_swap_quantity,
        streaming_swap_count,
        pool_slip,
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

  defp insert_swap(
         collection,
         pool,
         swap_slip,
         swap_target,
         liquidity_fee,
         liquidity_fee_in_rune,
         emit_asset,
         streaming_swap_quantity,
         streaming_swap_count,
         pool_slip,
         id,
         chain,
         from,
         to,
         coin,
         memo
       ) do
    swap_slip = String.to_integer(swap_slip)
    swap_target = String.to_integer(swap_target)
    liquidity_fee = String.to_integer(liquidity_fee)
    liquidity_fee_in_rune = String.to_integer(liquidity_fee_in_rune)
    streaming_swap_quantity = String.to_integer(streaming_swap_quantity)
    streaming_swap_count = String.to_integer(streaming_swap_count)
    pool_slip = String.to_integer(pool_slip)

    swap_data = %{
      pool: pool,
      swap_slip: swap_slip,
      swap_target: swap_target,
      liquidity_fee: liquidity_fee,
      liquidity_fee_in_rune: liquidity_fee_in_rune,
      emit_asset: emit_asset,
      streaming_swap_quantity: streaming_swap_quantity,
      streaming_swap_count: streaming_swap_count,
      pool_slip: pool_slip,
      id: id,
      chain: chain,
      from: from,
      to: to,
      coin: coin,
      memo: memo
    }

    [swap_data | collection]
  end
end
