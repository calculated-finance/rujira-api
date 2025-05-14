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
    events
    |> Enum.flat_map(&scan_event(&1))
    |> Enum.with_index()
    |> Enum.map(fn {event, idx} ->
      Map.merge(event, %{height: height, idx: idx, timestamp: time})
    end)
    |> Leagues.insert_tx_events()
    |> Leagues.update_leagues()

    {:noreply, state}
  end

  defp scan_event(%{attributes: attrs, type: "affiliate_fee"}) do
    IO.inspect(attrs)
    scan_attributes(attrs)
  end

  defp scan_event(_), do: []

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{key: "tx_id", value: tx_id},
           %{key: "memo", value: memo},
           %{key: "thorname", value: "rujira"},
           %{key: "rune_address", value: _},
           %{key: "asset", value: asset},
           %{key: "gross_amount", value: _},
           %{key: "fee_bps", value: _},
           %{key: "fee_amount", value: fee_amount}
           | rest
         ],
         collection
       ) do
    scan_attributes(rest, [league_event(asset, memo, fee_amount, tx_id) | collection])
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection

  defp league_event(asset, memo, fee_amount, tx_id) do
    with {:ok, address} <- Thorchain.get_dest_address(memo),
         {:ok, %{price: price, change: _}} <- Prices.get(asset) do
      affiliate_fee =
        fee_amount
        |> Decimal.mult(price)
        |> Decimal.round(0)
        |> Decimal.to_integer()

      %{address: address, revenue: affiliate_fee, txhash: tx_id, category: :swap}
    end
  end
end
