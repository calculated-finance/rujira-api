defmodule Rujira.Fin.Listener.Order do
  @moduledoc """
  Listens for and processes Fin Protocol-related blockchain events.

  Handles block transactions to detect Fin Protocol activities, updates cached data,
  and publishes real-time updates through the events system.
  """
  alias Rujira.Fin
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs}, state) do
    scan_txs(txs)

    {:noreply, state}
  end

  defp scan_txs(txs) do
    addresses =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)
      |> Enum.map(&scan_fin_event/1)
      |> Enum.reject(&is_nil/1)
      |> Rujira.Enum.uniq()
      # Trades are withdrawn before retraction. Ensure we're not re-publishing an order that doens't exist
      |> Enum.reverse()

    for {name, contract, owner, side, price} <- addresses do
      id = Enum.join([name, contract, owner, side, price], "/")
      Logger.info("#{__MODULE__} change #{id} ")

      Memoize.invalidate(Fin, :query_orders, [contract, owner, :_, :_])
      Memoize.invalidate(Fin, :query_order, [contract, owner, side, price])
      Logger.info("#{__MODULE__} invalidate #{id} ")

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

      Logger.info("#{__MODULE__} publish #{id}")
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
    # Where we can't know the owner (eg on trade events), we have to invalidate all
    owner = Map.get(attributes, "owner", :_)
    {name, contract_address, owner, side, price}
  end

  def scan_fin_event(_), do: nil
end
