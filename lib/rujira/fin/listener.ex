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
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) ->xs
        _ -> []
      end)
      |> Enum.flat_map(&scan_event/1)
      |> Enum.uniq()
      # Trades are withdrawn before retraction. Ensure we're not re-publishing an order that doens't exist
      |> Enum.reverse()

    for {name, contract, owner, side, price} <- addresses do
      Logger.debug("#{__MODULE__} change #{contract}")

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
            %{side: side, price: price, contract: contract},
            fin_order_updated: owner
          )
      end
    end

    for address <- addresses |> Enum.map(&elem(&1, 1)) |> Enum.uniq() do
      id = Absinthe.Relay.Node.to_global_id(:fin_book, address, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end
  end

  def scan_event(%{attributes: attributes, type: "wasm-rujira-fin/" <> name}) do
    scan_attributes(attributes, name)
  end

  def scan_event(_), do: []

  defp scan_attributes(
         attributes,
         name
       ) do
    map = Map.new(attributes, fn %{key: k, value: v} -> {k, v} end)
    address = Map.get(map, "_contract_address")
    side = Map.get(map, "side")
    price = Map.get(map, "price")
    owner = Map.get(map, "owner")
    [{name, address, owner, side, price}]
  end

end
