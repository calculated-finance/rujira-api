defmodule Rujira.Fin.Listener do
  alias Rujira.Fin
  alias Rujira.Bow
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
    events =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)

    addresses =
      events
      |> Enum.flat_map(&scan_event/1)
      |> Enum.uniq()
      # Trades are withdrawn before retraction. Ensure we're not re-publishing an order that doens't exist
      |> Enum.reverse()

    bow_addresses = events |> Enum.flat_map(&scan_bow_event/1) |> Enum.uniq()

    for address <- addresses |> Enum.map(&elem(&1, 1)) |> Enum.uniq() do
      Memoize.invalidate(Fin, :query_book, [address, :_])
      id = Absinthe.Relay.Node.to_global_id(:fin_book, address, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end

    for {address, pair} <- bow_addresses do
      Memoize.invalidate(Fin, :query_book, [pair, :_])
      Memoize.invalidate(Fin, :query_orders, [pair, address, :_, :_])

      id = Absinthe.Relay.Node.to_global_id(:fin_book, pair, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end

    for {name, contract, owner, side, price} <- addresses do
      Logger.debug("#{__MODULE__} change #{contract}")

      Memoize.invalidate(Fin, :query_orders, [contract, owner, :_, :_])
      Memoize.invalidate(Fin, :query_order, [contract, owner, side, price])

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

  def scan_bow_event(%{attributes: attributes, type: "wasm-rujira-bow/" <> _}) do
    scan_bow_attributes(attributes)
  end

  def scan_bow_event(_), do: []

  defp scan_bow_attributes(attributes) do
    map = Map.new(attributes, fn %{key: k, value: v} -> {k, v} end)
    address = Map.get(map, "_contract_address")

    with {:ok, pair} <- Bow.fin_pair(address) do
      [{address, pair}]
    end
  end
end
