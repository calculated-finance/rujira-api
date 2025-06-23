defmodule Rujira.Staking.Listener do
  @moduledoc """
  Listens for and processes staking-related blockchain events.

  Handles block transactions to detect staking events, updates cached data,
  and publishes real-time updates through the events system.
  """

  alias Rujira.Staking
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

    executions =
      events |> Enum.map(&scan_staking_event/1) |> Enum.reject(&is_nil/1) |> Rujira.Enum.uniq()

    transfers =
      events |> Enum.map(&scan_transfer/1) |> Enum.reject(&is_nil/1) |> Rujira.Enum.uniq()

    for {a, o} <- executions do
      Logger.debug("#{__MODULE__} execution #{a}")
      Memoize.invalidate(Staking, :query_account, [a, o])
      Memoize.invalidate(Staking, :query_pool, [a])
      Rujira.Events.publish_node(:staking_status, a)
      Rujira.Events.publish_node(:staking_account, "#{a}/#{o}")
    end

    for a <- transfers do
      Logger.debug("#{__MODULE__} transfer #{a}")
      Memoize.invalidate(Staking, :query_account, [a, :_])

      # We can indiscriminately publish all transfer events over the :staking_summary
      # subscription.
      # Most will be ignored unless the specific subscription is requested

      # TODO: Broadcast the same for transfers of `x/staking-` prefixed tokens
      Rujira.Events.publish_node(:staking_summary, a)
    end
  end

  def scan_staking_event(%{
        attributes: %{"_contract_address" => contract, "owner" => owner},
        type: "wasm-rujira-staking/" <> _
      }) do
    {contract, owner}
  end

  def scan_staking_event(_), do: nil

  def scan_transfer(%{attributes: %{"recipient" => recipient}, type: "transfer"}) do
    recipient
  end

  def scan_transfer(_), do: nil
end
