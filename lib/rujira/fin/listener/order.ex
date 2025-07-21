defmodule Rujira.Fin.Listener.Order do
  @moduledoc """
  Listens for order events on a specific Fin pair.

  Monitors order placements, cancellations, and trades. Invalidates order
  cache and publishes appropriate events (filled vs updated).
  """
  alias Rujira.Fin
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs}, %{address: address} = state) do
    # Extract order events from transactions and broadcast in reverse order
    txs
    |> Enum.flat_map(fn
      %{result: %{events: xs}} when is_list(xs) -> xs
      _ -> []
    end)
    |> Enum.map(&scan_fin_event(address, &1))
    |> Enum.reject(&is_nil/1)
    |> Rujira.Enum.uniq()
    # Trades are withdrawn before retraction. Ensure we're not re-publishing an order that doesn't exist
    |> Enum.reverse()
    |> Enum.each(&broadcast/1)

    {:noreply, state}
  end

  # Extracts order event details for this listener's contract address
  def scan_fin_event(address, %{
        attributes:
          %{
            "_contract_address" => contract_address,
            "side" => side,
            "price" => price
          } = attributes,
        type: "wasm-rujira-fin/" <> name
      })
      when contract_address == address do
    # Where we can't know the owner (eg on trade events), we have to invalidate all
    owner = Map.get(attributes, "owner", :_)
    {name, contract_address, owner, side, price}
  end

  def scan_fin_event(_, _), do: nil

  # Invalidates order cache and publishes appropriate event based on order type
  defp broadcast({name, contract, owner, side, price}) do
    id = Enum.join([name, contract, owner, side, price], "/")
    Logger.debug("#{__MODULE__} change #{id}")

    Memoize.invalidate(Fin, :query_orders, [contract, owner, :_, :_])
    Memoize.invalidate(Fin, :query_order, [contract, owner, side, price])

    case name do
      "trade" ->
        Rujira.Events.publish(%{side: side, price: price},
          fin_order_filled: "#{contract}/#{side}/#{price}"
        )

      _ ->
        # "trade" is caught already by the Pair listener
        Memoize.invalidate(Fin, :query_book, [contract, :_])
        Rujira.Events.publish_node(:fin_book, contract)

        Rujira.Events.publish(
          %{side: side, price: price, contract: contract},
          fin_order_updated: owner
        )
    end
  end
end
