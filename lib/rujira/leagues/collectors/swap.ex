defmodule Rujira.Leagues.Collectors.Swap do
  @moduledoc """
  Aggregates swap events and calculates league points.

  This module subscribes to new block events, scans for swap-related events,
  computes metrics (using prices and affiliate fees), converts addresses to Thor format,
  and inserts the resulting league events.
  """

  use GenServer
  alias Rujira.Prices
  alias Rujira.Leagues
  alias Phoenix.PubSub
  require Logger

  def start_link(default), do: GenServer.start_link(__MODULE__, default)

  @impl true
  def init(opts) do
    PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")
    {:ok, opts}
  end

  @impl true
  def handle_info(%{header: %{height: height, time: time}, end_block_events: events}, state) do
    scan_events(height, time, events)
    {:noreply, state}
  end

  defp scan_events(height, time, events) do
    {:ok, time, 0} = DateTime.from_iso8601(time)

    events
    |> Enum.flat_map(&scan_event(&1))
    |> Enum.with_index()
    |> Enum.map(fn {event, idx} ->
      Map.merge(event, %{height: height, idx: idx, timestamp: time})
    end)
    |> Leagues.insert_tx_events()
    |> Leagues.update_leagues()
  end

  defp scan_event(%{attributes: attrs}), do: scan_attributes(attrs)
  defp scan_event(attrs) when is_map(attrs), do: scan_attributes(Rujira.convert_attributes(attrs))

  # Recursively scan attributes, inserting events when a full set is found.
  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{key: "coin", value: coin},
           %{key: "emit_asset", value: emit_asset},
           %{key: "from", value: from},
           %{key: "id", value: id},
           %{key: "liquidity_fee", value: _},
           %{key: "liquidity_fee_in_rune", value: _},
           %{key: "memo", value: memo}
           | rest
         ],
         collection
       ) do
    scan_attributes(rest, insert_event(collection, emit_asset, from, coin, memo, id))
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection

  defp insert_event(collection, emit_asset, from, coin, memo, id) do
    with {:ok, {"rj", bps}} <- Thorchain.get_affiliate(memo),
         [coin_amt, coin_asset] <- String.split(coin, " ", parts: 2),
         {coin_amt, ""} <- Integer.parse(coin_amt),
         [emit_amt, emit_asset] <- String.split(emit_asset, " ", parts: 2),
         {emit_amt, ""} <- Integer.parse(emit_amt),
         {:ok, %{price: price, change: _}} <- Prices.get("RUNE") do
      affiliate_fee =
        swap_size_rune({coin_asset, coin_amt}, {emit_asset, emit_amt})
        |> Decimal.mult(price)
        |> Decimal.mult(bps)
        |> Decimal.round(0)
        |> Decimal.to_integer()

      event = %{address: from, revenue: affiliate_fee, txhash: id, category: :swap}
      [event | collection]
    else
      _ -> collection
    end
  end

  defp swap_size_rune({"THOR.RUNE", in_amount}, _), do: in_amount
  defp swap_size_rune(_, {"THOR.RUNE", out_amount}), do: out_amount
  defp swap_size_rune(_, _), do: 0
end
