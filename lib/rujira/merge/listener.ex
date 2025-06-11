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
    scan_attributes(attrs)
  end

  defp scan_event(_), do: []

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{value: contract_address, key: "_contract_address"},
           %{value: account, key: "account"}
           | rest
         ],
         collection
       ) do
    scan_attributes(rest, [{contract_address, account} | collection])
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection
end
