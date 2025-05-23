defmodule Thorchain.Swaps.Listener do
  alias Phoenix.PubSub
  use GenServer
  require Logger

  @impl true
  def init(opts) do
    PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")
    {:ok, opts}
  end

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def handle_info(%{end_block_events: events}, state) do
    scan_events(events)

    {:noreply, state}
  end

  defp scan_events(events) do
    swap_pools = events |> Enum.flat_map(&scan_event(&1)) |> Enum.uniq() |> IO.inspect()

    for pool <- swap_pools do
      Logger.debug("#{__MODULE__} change #{pool}")
      Memoize.invalidate(Thorchain, :oracle, ["THOR.RUNE"])
      Memoize.invalidate(Thorchain, :oracle, [pool])

      id = Absinthe.Relay.Node.to_global_id(:thorchain_oracle, pool, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
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
