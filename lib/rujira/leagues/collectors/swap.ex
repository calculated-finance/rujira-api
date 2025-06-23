defmodule Rujira.Leagues.Collectors.Swap do
  @moduledoc """
  Aggregates swap events and calculates league points.

  This module subscribes to new block events, scans for swap-related events,
  computes metrics (using prices and affiliate fees), converts addresses to Thor format,
  and inserts the resulting league events.
  """

  use Thornode.Observer
  alias Rujira.Leagues
  alias Rujira.Prices
  require Logger

  @impl true
  def handle_new_block(%{header: %{height: height, time: time}, end_block_events: events}, state) do
    events
    |> Enum.map(&scan_event/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.with_index()
    |> Enum.map(fn {event, idx} ->
      Map.merge(event, %{height: height, idx: idx, timestamp: time})
    end)
    |> Leagues.insert_tx_events()
    |> Leagues.update_leagues()

    {:noreply, state}
  end

  defp scan_event(%{
         attributes: %{
           "thorname" => thorname,
           "tx_id" => tx_id,
           "memo" => memo,
           "asset" => asset,
           "fee_amount" => fee_amount
         },
         type: "affiliate_fee"
       }) do
    case thorname do
      "rj" ->
        league_event(asset, memo, fee_amount, tx_id)

      _ ->
        nil
    end
  end

  defp scan_event(_), do: nil

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
