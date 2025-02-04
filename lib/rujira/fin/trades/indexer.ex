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
          header: %{height: height, time: time, last_block_id: %{hash: hash}},
          txs: txs,
          begin_block_events: begin_block_events,
          end_block_events: end_block_events
        },
        state
      ) do
    scan_events(height, 0, hash, begin_block_events, time)
    scan_events(height, 2_147_483_647, hash, end_block_events, time)

    for {%{hash: txhash, result: %{events: events}}, idx} <- Enum.with_index(txs) do
      scan_events(height, idx, txhash, events, time)
    end

    {:noreply, state}
  end

  defp scan_events(height, tx_idx, txhash, events, time) do
    events
    |> scan_attributes()
    |> Enum.with_index()
    |> Enum.each(fn {trade, idx} ->
      trade
      |> Map.merge(%{
        height: height,
        tx_idx: tx_idx,
        idx: idx,
        txhash: txhash,
        timestamp: time,
        protocol: "fin"
      })
      |> IO.inspect()
      # |> Trades.insert_trade()
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
             "bid" => bid
           }
           | rest
         ],
         collection
       ) do
    scan_attributes(
      rest,
      insert_trade(collection, contract_address, rate, offer, bid, "wasm-rujira-fin/trade")
    )
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection

  defp insert_trade(collection, contract_address, rate, offer, bid, type) do
    with {offer, _} <- Integer.parse(offer),
         {bid, _} <- Integer.parse(bid),
         {rate, _} <- Float.parse(rate) do
      trade = %{
        contract_address: contract_address,
        offer: offer,
        bid: bid,
        rate: rate,
        type: type
      }

      [trade | collection]
    end
  end
end
