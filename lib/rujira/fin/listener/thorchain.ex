defmodule Rujira.Fin.Listener.Thorchain do
  @moduledoc """
  Listens for and processes Fin Protocol-related blockchain events.

  Handles block transactions to detect Fin Protocol activities, updates cached data,
  and publishes real-time updates through the events system.
  """
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{end_block_events: end_block_events}, state) do
    end_block_events
    |> Enum.map(&scan_end_block_event/1)
    |> Enum.filter(&is_binary/1)
    |> Rujira.Enum.uniq()
    |> broadcast_swaps()

    {:noreply, state}
  end

  def scan_end_block_event(%{attributes: %{"pool" => pool}, type: "swap"}), do: pool
  def scan_end_block_event(_), do: nil

  defp broadcast_swaps(pools) when is_list(pools), do: Enum.each(pools, &broadcast_swap/1)

  defp broadcast_swap(pool) do
    Memoize.invalidate(Thorchain, :oracle_price, ["THOR.RUNE"])
    Memoize.invalidate(Thorchain, :oracle_price, [pool])
    Rujira.Events.publish_node(:thorchain_oracle, "THOR.RUNE")
    Rujira.Events.publish_node(:thorchain_oracle, pool)

    with {:ok, pools} <- Rujira.Fin.list_pairs() do
      pools
      |> Enum.filter(&(&1.oracle_base == pool or &1.oracle_quote == pool))
      |> Enum.each(fn %{address: address} ->
        Rujira.Events.publish_node(:fin_book, address)
      end)
    end
  end
end
