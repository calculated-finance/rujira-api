defmodule Rujira.Leagues.Collectors.Swap do
  @moduledoc """
  Aggregates swap events and calculates league points.

  This module subscribes to new block events, scans for swap-related events,
  computes metrics (using prices and affiliate fees), converts addresses to Thor format,
  and inserts the resulting league events.
  """

  use Thornode.Observer
  alias Rujira.Prices
  alias Rujira.Leagues
  require Logger

  @impl true
  def handle_new_block(%{header: %{height: height, time: time}, end_block_events: events}, state) do
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
    scan_attributes(attrs)
  end

  defp scan_event(_), do: []

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{key: "tx_id", value: tx_id},
           %{key: "memo", value: memo},
           %{key: "thorname", value: "rj"},
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
         {:ok, %{current: price}} <- Prices.tor_price(asset) do
      %{
        address: address,
        revenue:
          fee_amount
          |> Decimal.new()
          |> Decimal.mult(price)
          |> Decimal.round(0)
          |> Decimal.to_integer(),
        txhash: tx_id,
        category: :swap
      }
    end
  end
end
