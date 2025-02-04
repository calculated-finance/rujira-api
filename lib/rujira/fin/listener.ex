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
    addresses =
      txs
      |> Enum.flat_map(& &1["result"]["events"])
      |> scan_attributes()
      |> Enum.uniq()

    for a <- addresses do
      Logger.debug("#{__MODULE__} change #{a}")
      # TODO: Not happy with the Rujira app needing to know the graphql id schema.
      id = "contract:fin:#{a}:book"
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, id, node: id)
    end

    {:noreply, state}
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
