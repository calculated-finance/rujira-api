defmodule Rujira.Merge.Listener do
  @moduledoc """
  Listens for and processes Merge Protocol-related blockchain events.

  Handles block transactions to detect Merge Protocol activities, updates cached data,
  and publishes real-time updates through the events system.
  """

  alias Rujira.Merge
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs}, state) do
    scan_txs(txs)
    {:noreply, state}
  end

  defp scan_txs(txs) do
    addresses =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)
      |> Enum.map(&scan_event/1)
      |> Enum.reject(&is_nil/1)
      |> Rujira.Enum.uniq()

    for {a, account} <- addresses do
      Logger.debug("#{__MODULE__} change #{a}")
      Memoize.invalidate(Merge, :query_pool, [a])
      Memoize.invalidate(Merge, :query_account, [a, :_])
      Rujira.Events.publish_node(:merge_pool, a)
      Rujira.Events.publish_node(:merge_account, "#{a}/#{account}")
    end
  end

  defp scan_event(%{
         attributes: %{"_contract_address" => contract, "account" => account},
         type: "wasm-rujira-merge/" <> _
       }) do
    {contract, account}
  end

  defp scan_event(_), do: nil
end
