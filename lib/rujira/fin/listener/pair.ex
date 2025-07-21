defmodule Rujira.Fin.Listener.Pair do
  @moduledoc """
  Listens for trade events on a specific Fin pair.

  Monitors trade transactions to update order books when trades occur.
  Invalidates book cache and publishes book update events.
  """
  alias Rujira.Fin
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs}, %{address: address} = state) do
    # Extract trade events from transactions and broadcast order book updates
    events =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)

    events
    |> Enum.map(&scan_fin_event(address, &1))
    |> Enum.reject(&is_nil/1)
    |> Rujira.Enum.uniq()
    |> Enum.each(&broadcast/1)

    {:noreply, state}
  end

  # Filters trade events for this listener's specific contract address
  def scan_fin_event(address, %{
        attributes: %{"_contract_address" => contract_address},
        type: "wasm-rujira-fin/trade"
      })
      when contract_address == address,
      do: address

  def scan_fin_event(_, _), do: nil

  # Invalidates order book cache and publishes update event for trades
  defp broadcast(address) do
    Logger.debug("#{__MODULE__} change #{address}")
    Memoize.invalidate(Fin, :query_book, [address, :_])
    Rujira.Events.publish_node(:fin_book, address)
  end
end
