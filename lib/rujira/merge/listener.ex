defmodule Rujira.Merge.Listener do
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
    scan_txs(txs)
    {:noreply, state}
  end

  defp scan_txs(txs) do
    addresses =
      txs
      |> Enum.flat_map(fn x ->
        case x["result"]["events"] do
          nil -> []
          xs when is_list(xs) -> xs
        end
      end)
      |> scan_events()
      |> Enum.uniq()

    for {a, account} <- addresses do
      Logger.debug("#{__MODULE__} change #{a}")

      id = Absinthe.Relay.Node.to_global_id(:merge_pool, a, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
      id = Absinthe.Relay.Node.to_global_id(:merge_account, "#{a}/#{account}", RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end
  end

  defp scan_events(attributes, collection \\ [])

  defp scan_events(
         [%{"type" => "wasm-rujira-merge/" <> _, "account" => account} = event | rest],
         collection
       ) do
    address = Map.get(event, "_contract_address")
    scan_events(rest, [{address, account} | collection])
  end

  defp scan_events([_ | rest], collection), do: scan_events(rest, collection)
  defp scan_events([], collection), do: collection
end
