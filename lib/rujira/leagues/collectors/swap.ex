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
    |> Enum.flat_map(&scan_event/1)
    |> Enum.with_index()
    |> Enum.map(fn {event, idx} ->
      Map.merge(event, %{height: height, idx: idx, timestamp: time})
    end)
    |> Leagues.insert_tx_events()
    |> Leagues.update_leagues()

    {:noreply, state}
  end

  defp scan_event(%{attributes: attrs, type: "affiliate_fee"}) do
    thorname = Map.get(attrs, "thorname")

    case thorname do
      "rj" ->
        tx_id = Map.get(attrs, "tx_id")
        memo = Map.get(attrs, "memo")
        asset = Map.get(attrs, "asset")
        fee_amount = Map.get(attrs, "fee_amount")

        [league_event(asset, memo, fee_amount, tx_id)]

      _ ->
        []
    end
  end

  defp scan_event(_), do: []

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
