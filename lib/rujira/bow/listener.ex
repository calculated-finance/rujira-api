defmodule Rujira.Bow.Listener do
  use Thornode.Observer
  require Logger

  alias Rujira.Assets

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

    pools = events |> Enum.flat_map(&scan_pool/1) |> Enum.uniq()

    transfers =
      events
      |> Enum.flat_map(&scan_transfer/1)
      |> Enum.uniq()

    for pool <- pools do
      Logger.debug("#{__MODULE__} change #{pool}")
      Memoize.invalidate(Rujira.Bow, :query_pool, [pool])
      Memoize.invalidate(Rujira.Bow, :query_quotes, [pool])
      Rujira.Events.publish_node(:bow_pool_xyk, pool)

      # We use the FinBook on the UI to re-use thie Bok & History components from trade.
      # Broadcast a change to the FinBook that is scoped to the pool
      Rujira.Events.publish_node(:fin_book, pool)
    end

    for {denom, account} <- transfers do
      Logger.debug("#{__MODULE__} change #{denom} #{account}")
      Rujira.Events.publish_node(:bow_account, "#{account}/#{denom}")
    end
  end

  defp scan_pool(%{attributes: attrs, type: "wasm-rujira-bow/" <> _}) do
    contract = Map.get(attrs, "_contract_address")
    [contract]
  end

  defp scan_pool(_), do: []

  defp scan_transfer(%{
         type: "transfer",
         attributes: attrs
       }) do
    amount = Map.get(attrs, "amount")
    recipient = Map.get(attrs, "recipient")
    sender = Map.get(attrs, "sender")

    with {:ok, coins} <- Assets.parse_coins(amount) do
      coins
      |> Enum.filter(&is_lp_coin/1)
      |> Enum.flat_map(&merge_accounts(&1, [recipient, sender]))
    else
      _ -> []
    end
  end

  defp scan_transfer(_), do: []

  def is_lp_coin({"x/bow-" <> _, _}), do: true
  def is_lp_coin(_), do: false

  def merge_accounts({denom, _}, accounts) do
    Enum.map(accounts, &{denom, &1})
  end
end
