defmodule Rujira.Staking.Listener do
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

    executions = events |> Enum.flat_map(&scan_events(&1, :staking)) |> Enum.uniq()
    transfers = events |> Enum.flat_map(&scan_events(&1, :transfers)) |> Enum.uniq()

    for {a, o} <- executions do
      Logger.debug("#{__MODULE__} execution #{a}")
      Memoize.invalidate(Staking, :query_account, [a, o])
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

  def scan_events(%{attributes: attrs, type: "wasm-rujira-staking/" <> _}, :staking),
    do: scan_executions(attrs)

  def scan_events(%{attributes: attrs, type: "transfer"}, :transfers), do: scan_transfers(attrs)
  def scan_events(_, _), do: []

  defp scan_executions(attributes, collection \\ [])

  defp scan_executions(
         [
           %{value: contract_address, key: "_contract_address"},
           %{value: owner, key: "owner"}
           | rest
         ],
         collection
       ) do
    scan_executions(rest, [{contract_address, owner} | collection])
  end

  defp scan_executions([_ | rest], collection), do: scan_executions(rest, collection)
  defp scan_executions([], collection), do: collection

  defp scan_transfers(attributes, collection \\ [])

  defp scan_transfers(
         [%{value: recipient, key: "recipient"} | rest],
         collection
       ) do
    scan_transfers(rest, [recipient | collection])
  end

  defp scan_transfers([_ | rest], collection), do: scan_transfers(rest, collection)
  defp scan_transfers([], collection), do: collection
end
