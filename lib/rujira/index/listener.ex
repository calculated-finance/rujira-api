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

    vaults = events |> Enum.flat_map(&scan_event/1) |> Enum.uniq()
    accounts = events |> Enum.flat_map(&scan_transfer/1) |> Enum.uniq()

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

  defp scan_event(%{attributes: attrs, type: "wasm-nami-index" <> _}) do
    scan_attributes(attrs)
  end

  defp scan_event(_), do: []

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{value: contract_address, key: "_contract_address"}
           | rest
         ],
         collection
       ) do
    scan_attributes(rest, [contract_address | collection])
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection

  defp scan_transfer(%{
         type: "transfer",
         attributes: attrs
       }) do
    map =
      attrs |> Enum.reduce(%{}, fn %{key: key, value: value}, acc -> Map.put(acc, key, value) end)

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

  def is_index_coin({"x/nami-index-" <> _, _}), do: true
  def is_index_coin(_), do: false

  def merge_accounts({denom, _}, accounts) do
    Enum.map(accounts, &{denom, &1})
  end
end
