defmodule Thorchain.Swaps.Listener do
  @moduledoc """
  Listens for and processes Thorchain swap-related blockchain events.

  Handles block transactions to detect swap activities, updates cached data,
  and publishes real-time updates through the events system.
  """
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{end_block_events: events}, state) do
    scan_events(events)

    {:noreply, state}
  end

  defp scan_events(events) do
    swap_pools =
      events |> Enum.map(&scan_event(&1)) |> Enum.reject(&is_nil/1) |> Rujira.Enum.uniq()

    for pool <- swap_pools do
      Logger.debug("#{__MODULE__} change #{pool}")
      Memoize.invalidate(Thorchain, :oracle, ["THOR.RUNE"])
      Memoize.invalidate(Thorchain, :oracle, [pool])
      Rujira.Events.publish_node(:thorchain_oracle, pool)
      Rujira.Events.publish_node(:pool, pool)
    end
  end

  defp scan_event(%{attributes: %{"pool" => pool}, type: "swap"}), do: pool
  defp scan_event(_), do: nil
end
