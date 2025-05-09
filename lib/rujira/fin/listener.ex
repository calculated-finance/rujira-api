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
      # Trades are withdrawn before retraction. Ensure we're not re-publishing an order that doens't exist
      |> Enum.reverse()

    for {name, contract, owner, side, price} <- addresses do
      Logger.debug("#{__MODULE__} change #{contract}")

      id = Absinthe.Relay.Node.to_global_id(:fin_book, contract, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)

      case name do
        "trade" ->
          Absinthe.Subscription.publish(
            RujiraWeb.Endpoint,
            %{side: side, price: price},
            fin_order_filled: "#{contract}/#{side}/#{price}"
          )

        _ ->
          Absinthe.Subscription.publish(
            RujiraWeb.Endpoint,
            %{side: side, price: price},
            fin_order_updated: "#{contract}/#{owner}"
          )
      end
    end
  end

  defp scan_events(attributes, collection \\ [])

  defp scan_events(
         [%{"type" => "wasm-rujira-fin/" <> name} = event | rest],
         collection
       ) do
    address = Map.get(event, "_contract_address")
    side = Map.get(event, "side")
    price = Map.get(event, "price")
    owner = Map.get(event, "owner")
    scan_events(rest, [{name, address, owner, side, price} | collection])
  end

  defp scan_events([_ | rest], collection), do: scan_events(rest, collection)
  defp scan_events([], collection), do: collection
end
