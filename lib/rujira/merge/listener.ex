defmodule Rujira.Merge.Listener do
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
      |> Enum.flat_map(&scan_event/1)
      |> Enum.uniq()

    for {a, account} <- addresses do
      Logger.debug("#{__MODULE__} change #{a}")
      Memoize.invalidate(Merge, :query_pool, [a])
      Memoize.invalidate(Merge, :query_account, [a, :_])
      Rujira.Events.publish_node(:merge_pool, a)
      Rujira.Events.publish_node(:merge_account, "#{a}/#{account}")
    end
  end

  defp scan_event(%{attributes: attrs, type: "wasm-rujira-merge/" <> _}) do
    contract = Map.get(attrs, "_contract_address")
    account = Map.get(attrs, "account")
    [contract, account]
  end

  defp scan_event(_), do: []
end
