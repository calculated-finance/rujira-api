defmodule Rujira.Fin.Listener.Bow do
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
    addresses =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)
      |> Enum.map(&scan_bow_event/1)
      |> Enum.reject(&is_nil/1)
      |> Rujira.Enum.uniq()

    for address <- addresses do
      with {:ok, %{address: pair}} <- Bow.fin_pair(address) do
        Logger.debug("#{__MODULE__} bow change #{address}")
        Memoize.invalidate(Fin, :query_book, [pair, :_])
        Rujira.Events.publish_node(:fin_book, pair)
        Logger.debug("#{__MODULE__} bow change complete #{address}")
      end
    end
  end

  def scan_bow_event(%{
        attributes: %{"_contract_address" => contract_address},
        type: "wasm-rujira-bow/" <> _
      }) do
    contract_address
  end

  def scan_bow_event(_), do: nil
end
