defmodule Rujira.Fin.Indexer do
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
    for %{hash: txhash, result: %{events: events}} <- txs do
      scan_events(height, txhash, events, time)
    end

    {:noreply, state}
  end

  defp scan_events(height, txhash, events, time) do
    events
    |> Enum.flat_map(&scan_event/1)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {trade, idx} ->
      Map.merge(trade, %{
        height: height,
        idx: idx,
        txhash: txhash,
        timestamp: time,
        protocol: :fin
      })
    end)
    |> Rujira.Fin.insert_trades()
  end

  defp scan_event(%{attributes: attributes, type: "wasm-rujira-fin/trade"}) do
    scan_attributes(attributes)
  end

  defp scan_event(_), do: []

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{key: "_contract_address", value: contract_address},
           %{key: "bid", value: bid},
           %{key: "offer", value: offer},
           %{key: "price", value: price},
           %{key: "rate", value: rate},
           %{key: "side", value: side},
           %{key: "msg_index", value: msg_index}
           | rest
         ],
         collection
       ) do
    scan_attributes(
      rest,
      insert_trade(collection, contract_address, rate, price, offer, bid, msg_index, side)
    )
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection

  defp insert_trade(collection, contract_address, rate, price, offer, bid, msg_index, side) do
    with {offer, _} <- Integer.parse(offer),
         {bid, _} <- Integer.parse(bid),
         {tx_idx, _} <- Integer.parse(msg_index),
         {rate, _} <- Float.parse(rate) do
      if offer > 100 && bid > 100 do
        trade = %{
          contract: contract_address,
          offer: offer,
          bid: bid,
          rate: rate,
          price: price,
          side: String.to_existing_atom(side),
          tx_idx: tx_idx
        }

        [trade | collection]
      else
        collection
      end
    end
  end
end
