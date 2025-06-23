defmodule Rujira.Fin.Listener do
  @moduledoc """
  Listens for and processes Fin Protocol-related blockchain events.

  Handles block transactions to detect Fin Protocol activities, updates cached data,
  and publishes real-time updates through the events system.
  """
  alias Rujira.Bow
  alias Rujira.Fin
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs}, state) do
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
      |> Enum.map(&scan_fin_event/1)
      |> Enum.reject(&is_nil/1)
      |> Rujira.Enum.uniq()
      # Trades are withdrawn before retraction. Ensure we're not re-publishing an order that doens't exist
      |> Enum.reverse()

    bow_addresses =
      events |> Enum.map(&scan_bow_event/1) |> Enum.reject(&is_nil/1) |> Rujira.Enum.uniq()

    for address <- addresses |> Enum.map(&elem(&1, 1)) |> Rujira.Enum.uniq() do
      Memoize.invalidate(Fin, :query_book, [address, :_])
      Rujira.Events.publish_node(:fin_book, address)
    end

    for address <- bow_addresses do
      with {:ok, %{address: pair}} <- Bow.fin_pair(address) do
        Memoize.invalidate(Fin, :query_book, [pair, :_])
        Rujira.Events.publish_node(:fin_book, pair)
      end
    end

    for {name, contract, owner, side, price} <- addresses do
      Logger.debug("#{__MODULE__} change #{contract}")

      Memoize.invalidate(Fin, :query_orders, [contract, owner, :_, :_])
      Memoize.invalidate(Fin, :query_order, [contract, owner, side, price])

      case name do
        "trade" ->
          Rujira.Events.publish(%{side: side, price: price},
            fin_order_filled: "#{contract}/#{side}/#{price}"
          )

        _ ->
          Rujira.Events.publish(
            %{side: side, price: price, contract: contract},
            fin_order_updated: owner
          )
      end
    end
  end

  def scan_fin_event(%{
        attributes:
          %{
            "_contract_address" => contract_address,
            "side" => side,
            "price" => price
          } = attributes,
        type: "wasm-rujira-fin/" <> name
      }) do
    # owner can be missing on trade events
    owner = Map.get(attributes, "owner")
    {name, contract_address, owner, side, price}
  end

  def scan_fin_event(_), do: nil

  def scan_bow_event(%{
        attributes: %{"_contract_address" => contract_address},
        type: "wasm-rujira-bow/" <> _
      }) do
    contract_address
  end

  def scan_bow_event(_), do: nil
end
