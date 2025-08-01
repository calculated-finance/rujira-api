defmodule Rujira.Perps.Listener.Pool do
  @moduledoc """
  Listens for and processes Perps Protocol-related blockchain events.

  Handles block transactions to detect Perps Protocol activities, updates cached data,
  and publishes real-time updates through the events system.
  """

  alias Rujira.Perps
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs}, %{address: address} = state) do
    txs
    |> Enum.flat_map(fn
      %{result: %{events: xs}} when is_list(xs) -> xs
      _ -> []
    end)
    |> Enum.map(&scan_event(address, &1))
    |> Enum.reject(&is_nil/1)
    |> Rujira.Enum.uniq()
    |> Enum.each(&broadcast/1)

    {:noreply, state}
  end

  defp scan_event(address, %{
         attributes: %{"_contract_address" => contract},
         type: "wasm" <> _
       })
       when contract == address,
       do: address

  defp scan_event(_, _), do: nil

  defp broadcast(address) do
    Logger.debug("#{__MODULE__} change #{address}")
    # invalidate the pool
    Memoize.invalidate(Perps, :query_pool, [address])
    # invalidate all accounts related to the pool
    Memoize.invalidate(Perps, :query_account, [address, :_])

    # publish the pool
    Rujira.Events.publish_node(:perps_pool, address)

    # publish account on :perps_account_updated
    Rujira.Events.publish(%{contract: address}, perps_account_updated: address)
  end
end
