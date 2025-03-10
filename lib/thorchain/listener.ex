defmodule Thorchain.Listener do
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
  def handle_info(%{txs: txs}, state) do
    hashes =
      txs
      |> scan_txs()
      |> Enum.uniq()

    for a <- hashes do
      Logger.debug("#{__MODULE__} change #{a}")

      id =
        Absinthe.Relay.Node.to_global_id(:tx_in, a, RujiraWeb.Schema)

      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end

    {:noreply, state}
  end

  defp scan_txs(txs, collection \\ [])

  defp scan_txs(
         [
           %{"tx" => %{"body" => %{"messages" => messages}}}
           | rest
         ],
         collection
       ) do
    ids =
      Enum.reduce(messages, [], fn
        %{"@type" => "/types.MsgObservedTxIn", "txs" => txs}, acc ->
          txs |> Enum.map(& &1["tx"]["id"]) |> Enum.concat(acc)

        _, acc ->
          acc
      end)

    scan_txs(rest, Enum.concat(ids, collection))
  end

  defp scan_txs([_ | rest], collection), do: scan_txs(rest, collection)
  defp scan_txs([], collection), do: collection
end
