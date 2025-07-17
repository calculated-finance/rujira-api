defmodule Rujira.Fin.Listener.Pair do
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

    for address <- addresses |> Rujira.Enum.uniq() do
      Logger.info("#{__MODULE__} change #{address}")
      count = Memoize.invalidate(Fin, :query_book, [address, :_])
      Logger.info("#{__MODULE__} invalidate #{address} count #{count}")
      Rujira.Events.publish_node(:fin_book, address)
      Logger.info("#{__MODULE__} publish #{address}")
    end
  end

  def scan_fin_event(%{
        attributes: %{"_contract_address" => contract_address},
        type: "wasm-rujira-fin/trade"
      }) do
    contract_address
  end

  def scan_fin_event(_), do: nil
end
