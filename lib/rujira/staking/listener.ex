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

    executions = events |> Enum.flat_map(&scan_staking_event/1) |> Enum.uniq()
    transfers = events |> Enum.flat_map(&scan_transfer/1) |> Enum.uniq()

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

  def scan_staking_event(%{attributes: attrs, type: "wasm-rujira-staking/" <> _}) do
    contract = Map.get(attrs, "_contract_address")
    owner = Map.get(attrs, "owner")
    [{contract, owner}]
  end

  def scan_staking_event(_), do: []

  def scan_transfer(%{attributes: attrs, type: "transfer"}) do
    [Map.get(attrs, "recipient")]
  end

  def scan_transfer(_), do: []
end
