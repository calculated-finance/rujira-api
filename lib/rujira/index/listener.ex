defmodule Rujira.Index.Listener do
  @moduledoc """
  Listens for and processes Index Protocol-related blockchain events.

  Handles block transactions to detect Index Protocol activities, updates cached data,
  and publishes real-time updates through the events system.
  """
  alias Rujira.Assets
  alias Rujira.Index

  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs}, state) do
    scan_txs(txs)
    {:noreply, state}
  end

  defp scan_txs(txs) do
    events = Enum.flat_map(txs, fn %{result: %{events: xs}} when is_list(xs) -> xs end)

    vaults = events |> Enum.map(&scan_vault/1) |> Enum.reject(&is_nil/1) |> Rujira.Enum.uniq()
    accounts = events |> Enum.flat_map(&scan_transfer/1) |> Rujira.Enum.uniq()
    sudo = events |> Enum.map(&scan_sudo/1) |> Enum.reject(&is_nil/1) |> Rujira.Enum.uniq()

    for a <- sudo do
      Logger.debug("#{__MODULE__} change #{a}")
      Memoize.invalidate(Index, :query_status, [a])
      Rujira.Events.publish_node(:index_vault, a)
    end

    for a <- vaults do
      Logger.debug("#{__MODULE__} change #{a}")
      Memoize.invalidate(Index, :query_status, [a])
      Rujira.Events.publish_node(:index_vault, a)
    end

    for {denom, account} <- accounts do
      Logger.debug("#{__MODULE__} change #{denom} #{account}")
      Rujira.Events.publish_node(:index_account, "#{account}/#{denom}")
    end
  end

  defp scan_vault(%{
         attributes: %{"_contract_address" => contract_address},
         type: "wasm-nami-index" <> _
       }) do
    contract_address
  end

  defp scan_vault(_), do: nil

  defp scan_transfer(%{
         attributes: %{"amount" => amount, "recipient" => recipient, "sender" => sender},
         type: "transfer"
       }) do
    with {:ok, coins} <- Assets.parse_coins(amount) do
      coins
      |> Enum.filter(&index_coin?/1)
      |> Enum.flat_map(&merge_accounts(&1, [recipient, sender]))
    end
  end

  defp scan_transfer(_), do: []

  defp scan_sudo(%{
         attributes: %{"_contract_address" => contract_address},
         type: "sudo"
       }) do
    contract_address
  end

  defp scan_sudo(_), do: nil

  def index_coin?({"x/nami-index-" <> _, _}), do: true
  def index_coin?(_), do: false

  def merge_accounts({denom, _}, accounts) do
    Enum.map(accounts, &{denom, &1})
  end
end
