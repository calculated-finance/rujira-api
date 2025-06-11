defmodule Thorchain.Swaps.Listener do
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{end_block_events: events}, state) do
    scan_events(events)

    {:noreply, state}
  end

  defp scan_events(events) do
    swap_pools = events |> Enum.flat_map(&scan_event(&1)) |> Enum.uniq()

    for pool <- swap_pools do
      Logger.debug("#{__MODULE__} change #{pool}")
      Memoize.invalidate(Thorchain, :oracle, ["THOR.RUNE"])
      Memoize.invalidate(Thorchain, :oracle, [pool])
      Rujira.Events.publish_node(:thorchain_oracle, pool)
      Rujira.Events.publish_node(:pool, pool)
    end
  end

  defp scan_event(%{attributes: attributes, type: "swap"}) do
    scan_attributes(attributes)
  end

  defp scan_event(_), do: []

  defp scan_attributes(attributes) do
    map = Map.new(attributes, fn %{key: k, value: v} -> {k, v} end)
    [Map.get(map, "pool")]
  end
end
