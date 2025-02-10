defmodule Rujira.Fin.Listener do
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

  def handle_info(%{id: %{txs: txs}}, state) do
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
      |> scan_attributes()
      |> Enum.uniq()

    for a <- addresses do
      Logger.debug("#{__MODULE__} change #{a}")

      id =
        Absinthe.Relay.Node.to_global_id(:fin_book, a, RujiraWeb.Schema)

      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end
  end

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{
             "_contract_address" => address,
             "type" => "wasm-rujira-fin/" <> _
           }
           | rest
         ],
         collection
       ) do
    scan_attributes(rest, [address | collection])
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection
end
