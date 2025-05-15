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
      |> Enum.flat_map(&scan_txs/1)
      |> Enum.uniq()

    for a <- hashes do
      Logger.debug("#{__MODULE__} change #{a}")

      id =
        Absinthe.Relay.Node.to_global_id(:tx_in, a, RujiraWeb.Schema)

      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end

    {:noreply, state}
  end

  defp scan_txs(%{tx_data: tx_data}) do
    with {:ok, decoded} <- Jason.decode(tx_data) do
      scan_tx(decoded)
    end
  end

  defp scan_tx(%{"body" => %{"messages" => messages}}) do
    IO.inspect(messages)
    Enum.reduce(messages, [], fn
      %{"@type" => "/types.MsgObservedTxIn", "txs" => txs}, acc ->
        txs |> Enum.map(& &1["tx"]["id"]) |> Enum.concat(acc)

      _, acc ->
        acc
    end)
  end

  defp scan_tx(_), do: []
end
