defmodule Rujira.Bow.Listener do
  @moduledoc """
  Listens for and processes Bow Protocol-related blockchain events.

  Handles block transactions to detect Bow Protocol actions, updates cached data,
  and publishes real-time updates through the events system.
  """
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

    pools = events |> Enum.map(&scan_pool/1) |> Enum.reject(&is_nil/1) |> Rujira.Enum.uniq()

    transfers =
      events
      |> Enum.flat_map(&scan_transfer/1)
      |> Rujira.Enum.uniq()

    for pool <- pools do
      Logger.debug("#{__MODULE__} change #{pool}")
      Memoize.invalidate(Rujira.Bow, :query_pool, [pool])
      Memoize.invalidate(Rujira.Bow, :query_quotes, [pool])
      Rujira.Events.publish_node(:bow_pool_xyk, pool)

      # We use the FinBook on the UI to re-use the Bok & History components from trade.
      # Broadcast a change to the FinBook that is scoped to the pool
      Rujira.Events.publish_node(:fin_book, pool)
    end

    for {denom, account} <- transfers do
      Logger.debug("#{__MODULE__} change #{denom} #{account}")
      Rujira.Events.publish_node(:bow_account, "#{account}/#{denom}")
    end
  end

  defp scan_pool(%{attributes: %{"_contract_address" => contract}, type: "wasm-rujira-bow/" <> _}),
    do: contract

  defp scan_pool(_), do: nil

  defp scan_transfer(%{
         type: "transfer",
         attributes: %{"amount" => amount, "recipient" => recipient, "sender" => sender}
       }) do
    case Assets.parse_coins(amount) do
      {:ok, coins} ->
        coins
        |> Enum.filter(&lp_coin?/1)
        |> Enum.flat_map(&merge_accounts(&1, [recipient, sender]))

      _ ->
        []
    end
  end

  defp scan_transfer(_), do: []

  def lp_coin?({"x/bow-" <> _, _}), do: true
  def lp_coin?(_), do: false

  def merge_accounts({denom, _}, accounts) do
    Enum.map(accounts, &{denom, &1})
  end
end
