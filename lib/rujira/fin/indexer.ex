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
    |> Enum.flat_map(&scan_trade/1)
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

  defp scan_trade(%{attributes: attributes, type: "wasm-rujira-fin/trade"}) do
    contract_address = Map.get(attributes, "_contract_address")
    bid = Map.get(attributes, "bid")
    offer = Map.get(attributes, "offer")
    price = Map.get(attributes, "price")
    rate = Map.get(attributes, "rate")
    side = Map.get(attributes, "side")

    insert_trade(contract_address, rate, price, offer, bid, side)
  end

  defp scan_trade(_), do: []

  defp insert_trade(contract_address, rate, price, offer, bid, side) do
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

        [trade]
      else
        []
      end
    end
  end
end
