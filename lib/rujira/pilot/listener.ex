defmodule Rujira.Pilot.Listener do
  @moduledoc """
  Listens for and processes Rujira Pilot blockchain events.

  Handles block transactions to detect Pilot actions, updates cached data,
  and publishes real-time updates through the events system.
  """

  alias Rujira.Keiko
  alias Rujira.Pilot
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
      |> Enum.flat_map(&scan_pilot_event/1)
      |> Enum.uniq()

    for {contract, owner, premium} <- addresses do
      Logger.debug("#{__MODULE__} change #{contract} owner=#{owner} premium=#{premium}")

      # Always Invalidate Keiko Sale
      Memoize.invalidate(Keiko, :query_sale, [:_])

      # Invalidate pilot bid pools to trigger a reload
      Memoize.invalidate(Pilot, :query_pools, [contract, :_, :_])

      # Invalidate pilot orders to trigger a reload and publish an update event
      Memoize.invalidate(Pilot, :query_order, [contract, owner, premium])

      # invalidate bids for a specific account
      Memoize.invalidate(Pilot, :query_bids, [contract, owner, :_, :_])

      # publish events for account updates
      Rujira.Events.publish_node(:pilot_account, "#{contract}/#{owner}")

      # publish events for bid pools and order updates
      Rujira.Events.publish_node(:pilot_bid_pools, contract)

      Rujira.Events.publish(
        %{premium: premium, contract: contract},
        pilot_bid_updated: owner
      )
    end
  end

  def scan_pilot_event(%{
        attributes: %{"_contract_address" => contract, "owner" => owner, "premium" => premium},
        type: "wasm-rujira-pilot/" <> _
      }) do
    [{contract, owner, premium}]
  end

  def scan_pilot_event(_), do: []
end
