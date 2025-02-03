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
    swaps = Enum.flat_map(events, &scan_event/1)

    with {:ok, %{rune_price_in_tor: price}} <- Thorchain.network(),
         price <- String.to_integer(price) do
      for {swap, idx} <- Enum.with_index(swaps) do
        liquidity_fee_in_usd =
          Prices.normalize(String.to_integer(swap.liquidity_fee_in_rune) * price, 16)

        volume_usd = get_volume(swap, price)

        aff_data = get_affiliate_data(swap, price, volume_usd)

        swap
        |> Map.merge(%{
          height: height,
          tx_idx: tx_idx,
          idx: idx,
          timestamp: time,
          liquidity_fee_in_usd: Integer.to_string(liquidity_fee_in_usd),
          volume_usd: Integer.to_string(volume_usd)
        })
        |> Map.merge(aff_data)
        |> Swaps.insert_swap()
      end
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
         collection
       ) do
    scan_attributes(
      rest,
      [
        %{
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
        }
        | collection
      ]
    )
  end

  defp scan_attributes([_ | rest], collection) do
    scan_attributes(rest, collection)
  end

  defp scan_attributes([], collection), do: collection

  defp get_volume(swap, price) do
    [coin_amount, coin_type] = String.split(swap.coin, " ", parts: 2)
    [emit_amount, emit_type] = String.split(swap.emit_asset, " ", parts: 2)

    volume =
      cond do
        String.contains?(coin_type, "THOR.RUNE") -> String.to_integer(coin_amount) * price
        String.contains?(emit_type, "THOR.RUNE") -> String.to_integer(emit_amount) * price
        true -> 0
      end

    Rujira.Prices.normalize(volume, 16)
  end

  defp get_affiliate_data(swap, price, volume_usd) do
    case Thorchain.get_affiliate(swap.memo) do
      {:ok, {aff, bps}} ->
        case Integer.parse(bps) do
          {bps_value, ""} ->
            affiliate_fee = volume_usd * bps_value / 10_000

            %{
              affiliate: aff,
              affiliate_bps: Integer.to_string(bps_value),
              affiliate_fee_in_rune:
                Integer.to_string(Prices.normalize(affiliate_fee / price, 4)),
              affiliate_fee_in_usd: Integer.to_string(Float.round(affiliate_fee) |> trunc())
            }

          :error ->
            %{}
        end

      {:error, :no_affiliate} ->
        %{}
    end
  end
end
