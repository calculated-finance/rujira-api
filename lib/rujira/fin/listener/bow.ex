defmodule Rujira.Fin.Listener.Bow do
  @moduledoc """
  Listens for Bow market maker events on a specific pair.

  Monitors blockchain transactions for Bow-related events, invalidates
  order book cache when changes occur, and publishes book updates.
  """
  alias Rujira.Bow
  alias Rujira.Fin
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs}, %{address: address} = state) do
    # Extract Bow events from transactions and broadcast changes
    txs
    |> Enum.flat_map(fn
      %{result: %{events: xs}} when is_list(xs) -> xs
      _ -> []
    end)
    |> Enum.map(&scan_bow_event(address, &1))
    |> Enum.reject(&is_nil/1)
    |> Rujira.Enum.uniq()
    |> Enum.each(&broadcast/1)

    {:noreply, state}
  end

  # Filters Bow events for this listener's specific contract address
  def scan_bow_event(address, %{
        attributes: %{"_contract_address" => contract_address},
        type: "wasm-rujira-bow/" <> _
      })
      when contract_address == address,
      do: address

  def scan_bow_event(_, _), do: nil

  # Invalidates order book cache and publishes update event
  defp broadcast(address) do
    with {:ok, %{address: pair}} <- Bow.fin_pair(address) do
      Logger.debug("#{__MODULE__} bow change #{address}")
      Memoize.invalidate(Fin, :query_book, [pair, :_])
      Rujira.Events.publish_node(:fin_book, pair)
    end
  end
end
