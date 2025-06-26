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

    for {addr, denom} <- transfers do
      case denom do
        # We catch staking events above, so this is only concerned with balance transfers
        # va MsgSend etc, which will only affect an account
        # No need to invalidate, query_account only queries the account-based staking, .
        # not the liquid staking
        "x/staking-" <> id ->
          Rujira.Events.publish_node(:staking_account, "#{addr}/#{id}")

        # These are potentialyl sends to the staking contract which affect pending rewards and liquid stqaked value.
        # Invalidate and publish all, as invalidations & events published will only hit active subscriptions etc.
        # And so it's cheaper than looking up the contract address each time
        _ ->
          Memoize.invalidate(Staking, :query_account, [addr, :_])
          Memoize.invalidate(Staking, :query_pool, [addr])
          Rujira.Events.publish_node(:staking_summary, addr)
          Rujira.Events.publish_node(:staking_status, addr)
          # We can't do this one - it's the trade-off keying the accoubt by receipt token;
          # we'd have to look the bond_denom up by addr
          # Rujira.Events.publish_node(:staking_account, "#{a}/#{o}")
      end
    end
  end

  def scan_staking_event(%{
        attributes: %{"_contract_address" => contract, "owner" => owner},
        type: "wasm-rujira-staking/" <> _
      }) do
    {contract, owner}
  end

  def scan_staking_event(_), do: nil

  defp scan_transfer(%{
         attributes: %{"recipient" => recipient, "sender" => sender, "amount" => amount},
         type: "transfer"
       }) do
    amount
    |> String.split(",")
    |> Enum.map(&String.replace(&1, ~r/^[0-9]+/, ""))
    |> Enum.flat_map(&[{recipient, &1}, {sender, &1}])
  end

  defp scan_transfer(_), do: nil
end
