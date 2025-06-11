defmodule Rujira.Fin.Indexer do
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
    |> Enum.flat_map(&scan_event/1)
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
           %{key: "side", value: side}
           | rest
         ],
         collection
       ) do
    scan_attributes(
      rest,
      insert_trade(collection, contract_address, rate, price, offer, bid, side)
    )
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection

  defp insert_trade(collection, contract_address, rate, price, offer, bid, side) do
    with {offer, _} <- Integer.parse(offer),
         {bid, _} <- Integer.parse(bid),
         {rate, _} <- Float.parse(rate) do
      if offer > 100 && bid > 100 do
        trade = %{
          contract: contract_address,
          offer: offer,
          bid: bid,
          rate: rate,
          price: price,
          side: String.to_existing_atom(side)
        }

        [trade | collection]
      else
        collection
      end
    end
  end
end
