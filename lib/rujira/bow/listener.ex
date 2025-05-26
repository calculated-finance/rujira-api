defmodule Rujira.Bow.Listener do
  use GenServer
  require Logger

  alias Rujira.Assets

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(state) do
    Phoenix.PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")
    {:ok, state}
  end

  @impl true
  def handle_info(%{txs: txs}, state) do
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

    pools = events |> Enum.flat_map(&scan_event/1) |> Enum.uniq()

    transfers =
      events
      |> Enum.flat_map(&scan_transfer/1)
      |> Enum.uniq()

    for {pool, account} <- pools do
      Logger.debug("#{__MODULE__} change #{pool} #{account}")
      Memoize.invalidate(Rujira.Bow, :query_pool, [pool])
      Memoize.invalidate(Rujira.Bow, :query_quotes, [pool])

      id = Absinthe.Relay.Node.to_global_id(:bow_pool, pool, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)

      # We use the FinBook on the UI to re-use thie Bok & History components from trade.
      # Broadcast a change to the FinBook that is scoped to the pool
      id = Absinthe.Relay.Node.to_global_id(:fin_book, pool, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end

    for {denom, account} <- transfers do
      Logger.debug("#{__MODULE__} change #{denom} #{account}")
      id = Absinthe.Relay.Node.to_global_id(:bow_account, "#{account}/#{denom}", RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end
  end

  defp scan_event(%{attributes: attrs, type: "wasm-rujira-bow/" <> _}) do
    scan_attributes(attrs)
  end

  defp scan_event(_), do: []

  defp scan_attributes(attrs) do
    attr_map = Map.new(attrs, fn %{key: k, value: v} -> {k, v} end)
    contract = Map.get(attr_map, "_contract_address")
    owner = Map.get(attr_map, "owner")
    [{contract, owner}]
  end

  # TODO: handle x/wasm events being in a different order
  defp scan_transfer(%{
         type: "transfer",
         attributes: [
           %{key: "recipient", value: recipient},
           %{key: "sender", value: sender},
           %{key: "amount", value: amount} | _
         ]
       }) do
    with {:ok, coins} <- Assets.parse_coins(amount) do
      coins
      |> Enum.filter(&is_lp_coin/1)
      |> Enum.flat_map(&merge_accounts(&1, [recipient, sender]))
    else
      _ -> []
    end
  end

  defp scan_transfer(%{
         type: "transfer",
         attributes: [
           %{key: "amount", value: amount},
           %{key: "recipient", value: recipient},
           %{key: "sender", value: sender} | _
         ]
       }) do
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
