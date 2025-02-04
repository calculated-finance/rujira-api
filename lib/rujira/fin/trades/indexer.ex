defmodule Rujira.Fin.Trades.Indexer do
  alias Rujira.Fin.Trades
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(state) do
    Phoenix.PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")
    {:ok, state}
  end

  @impl true
  def handle_info(
        %{
          header: %{height: height, time: time},
          txs: txs
        },
        state
      ) do
    for %{"hash" => txhash, "result" => %{"events" => events}} <- txs do
      scan_events(height, txhash, events, time)
    end

    {:noreply, state}
  end

  defp scan_events(height, txhash, events, time) do
    events
    |> scan_attributes()
    |> Enum.with_index()
    |> Enum.each(fn {trade, idx} ->
      Map.merge(trade, %{
        height: height,
        idx: idx,
        txhash: txhash,
        timestamp: time,
        protocol: "fin"
      })
      |> Trades.insert_trade()
    end)
  end

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{
             "_contract_address" => contract_address,
             "type" => "wasm-rujira-fin/trade",
             "rate" => rate,
             "offer" => offer,
             "bid" => bid,
             "msg_index" => msg_index,
             "side" => side
           }
           | rest
         ],
         collection
       ) do
    scan_attributes(
      rest,
      insert_trade(collection, contract_address, rate, offer, bid, msg_index, side)
    )
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection

  defp insert_trade(collection, contract_address, rate, offer, bid, msg_index, side) do
    with {offer, _} <- Integer.parse(offer),
         {bid, _} <- Integer.parse(bid),
         {tx_idx, _} <- Integer.parse(msg_index),
         {rate, _} <- Float.parse(rate) do
      trade = %{
        contract_address: contract_address,
        offer: offer,
        bid: bid,
        rate: rate,
        side: side,
        tx_idx: tx_idx
      }

      [trade | collection]
    end
  end
end
