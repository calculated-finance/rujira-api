defmodule Rujira.Fin.Listener.Thorchain do
  @moduledoc """
  Listens for and processes Fin Protocol-related blockchain events.

  Handles block transactions to detect Fin Protocol activities, updates cached data,
  and publishes real-time updates through the events system.
  """
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(
        %{end_block_events: end_block_events},
        %{
          address: address,
          oracle_base: oracle_base,
          oracle_quote: oracle_quote
        } = state
      ) do
    end_block_events
    |> Enum.map(&scan_end_block_event(oracle_base, oracle_quote, &1))
    |> Enum.filter(&is_binary/1)
    |> Rujira.Enum.uniq()
    |> broadcast_swaps(address)

    {:noreply, state}
  end

  def scan_end_block_event(oracle_base, oracle_quote, %{
        attributes: %{"pool" => pool},
        type: "swap"
      })
      when pool == oracle_base or pool == oracle_quote,
      do: pool

  def scan_end_block_event(_, _, _), do: nil

  defp broadcast_swaps(pools, address) when is_list(pools),
    do: Enum.each(pools, &broadcast_swap(&1, address))

  defp broadcast_swap(pool, address) do
    Logger.debug("#{__MODULE__} change #{address} (#{pool})")

    Memoize.invalidate(Thorchain, :oracle_price, ["THOR.RUNE"])
    Memoize.invalidate(Thorchain, :oracle_price, [pool])
    Logger.info("#{__MODULE__} invalidate #{pool}")

    Rujira.Events.publish_node(:thorchain_oracle, "THOR.RUNE")
    Rujira.Events.publish_node(:thorchain_oracle, pool)
    Rujira.Events.publish_node(:fin_book, address)
  end
end
