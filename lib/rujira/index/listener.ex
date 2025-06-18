defmodule Rujira.Index.Listener do
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

    vaults = events |> Enum.flat_map(&scan_vault/1) |> Enum.uniq()
    accounts = events |> Enum.flat_map(&scan_transfer/1) |> Enum.uniq()
    sudo = events |> Enum.flat_map(&scan_sudo/1) |> Enum.uniq()

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

  defp scan_vault(%{attributes: attrs, type: "wasm-nami-index" <> _}) do
    map =
      Enum.reduce(attrs, %{}, fn %{key: key, value: value}, acc -> Map.put(acc, key, value) end)

    contract_address = Map.get(map, "_contract_address")

    [contract_address]
  end

  defp scan_vault(_), do: []

  defp scan_transfer(%{
         type: "transfer",
         attributes: attrs
       }) do
    map =
      Enum.reduce(attrs, %{}, fn %{key: key, value: value}, acc -> Map.put(acc, key, value) end)

    amount = Map.get(map, "amount")
    recipient = Map.get(map, "recipient")
    sender = Map.get(map, "sender")

    with {:ok, coins} <- Assets.parse_coins(amount) do
      coins
      |> Enum.filter(&is_index_coin/1)
      |> Enum.flat_map(&merge_accounts(&1, [recipient, sender]))
    end
  end

  defp scan_transfer(_), do: []

  defp scan_sudo(%{
         type: "sudo",
         attributes: attrs
       }) do
    map =
      Enum.reduce(attrs, %{}, fn %{key: key, value: value}, acc -> Map.put(acc, key, value) end)

    contract_address = Map.get(map, "_contract_address")
    [contract_address]
  end

  defp scan_sudo(_), do: []

  def is_index_coin({"x/nami-index-" <> _, _}), do: true
  def is_index_coin(_), do: false

  def merge_accounts({denom, _}, accounts) do
    Enum.map(accounts, &{denom, &1})
  end
end
