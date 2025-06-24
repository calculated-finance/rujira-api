defmodule Rujira.Balances.Listener do
  @moduledoc """
  Listens for and processes balance-related blockchain events.

  Handles block transactions to detect balance changes, updates cached data,
  and publishes real-time updates through the events system.
  """
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(
        %{txs: txs, begin_block_events: begin_block_events, end_block_events: end_block_events},
        state
      ) do
    addresses =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)
      |> Enum.concat(begin_block_events)
      |> Enum.concat(end_block_events)
      |> Enum.flat_map(&scan_transfer/1)
      |> Rujira.Enum.uniq()

    for {a, denom} <- addresses do
      Logger.debug("#{__MODULE__} change #{a}")
      Memoize.invalidate(Rujira.Chains.Thor, :balance_of, [a, denom])
      Rujira.Events.publish_node(:layer_1_account, "thor:#{a}")
    end

    {:noreply, state}
  end

  defp scan_transfer(%{
         attributes: %{"recipient" => recipient, "sender" => sender, "amount" => amount},
         type: "transfer"
       }) do
    amount
    |> String.split(",")
    |> Enum.map(&String.replace(&1, ~r/^[0-9]+/, ""))
    |> Enum.flat_map(&[{recipient, &1}, {sender, &1}])
  end

  defp scan_transfer(_), do: []
end
