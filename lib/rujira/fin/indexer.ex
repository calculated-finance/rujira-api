defmodule Rujira.Fin.Indexer do
  @moduledoc """
  Listens for and indexes trading events from the FIN protocol.

  This module implements the `Thornode.Observer` behavior to monitor and process
  blockchain events related to trading activity, extracting and storing trade data
  for financial analysis and reporting.
  """
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(
        %{
          header: %{height: height, time: time},
          txs: txs
        },
        state
      ) do
    for {%{hash: txhash, result: %{events: events}}, tx_idx} <- Enum.with_index(txs) do
      scan_events(height, txhash, tx_idx, events, time)
    end

    {:noreply, state}
  end

  defp scan_events(height, txhash, tx_idx, events, time) do
    events
    |> Enum.map(&scan_trade/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.with_index()
    |> Enum.map(fn {trade, idx} ->
      Map.merge(trade, %{
        height: height,
        tx_idx: tx_idx,
        idx: idx,
        txhash: txhash,
        timestamp: time,
        protocol: :fin
      })
    end)
    |> Rujira.Fin.insert_trades()
  end

  defp scan_trade(%{
         attributes: %{
           "_contract_address" => contract_address,
           "bid" => bid,
           "offer" => offer,
           "price" => price,
           "rate" => rate,
           "side" => side
         },
         type: "wasm-rujira-fin/trade"
       }) do
    insert_trade(contract_address, rate, price, offer, bid, side)
  end

  defp scan_trade(_), do: nil

  defp insert_trade(contract_address, rate, price, offer, bid, side) do
    with {offer, _} <- Integer.parse(offer),
         {bid, _} <- Integer.parse(bid),
         {rate, _} <- Float.parse(rate) do
      if offer > 100 && bid > 100 do
        %{
          contract: contract_address,
          offer: offer,
          bid: bid,
          rate: rate,
          price: price,
          side: String.to_existing_atom(side)
        }
      else
        nil
      end
    end
  end
end
