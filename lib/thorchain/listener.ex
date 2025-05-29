defmodule Thorchain.Listener do
  use GenServer
  require Logger

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
    hashes =
      txs
      |> Enum.flat_map(&scan_txs/1)
      |> Enum.uniq()

    for a <- hashes do
      Logger.debug("#{__MODULE__} change #{a}")
      Rujira.Events.publish_node(:tx_in, a)
    end

    events =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)

    for {pool, address} <- events |> Enum.flat_map(&scan_event/1) |> Enum.uniq() do
      Memoize.invalidate(Thorchain, :liquidity_provider, [pool, address])

      Rujira.Events.publish_node(:thorchain_liquidity_provider, "#{pool}/#{address}")
      Rujira.Events.publish_node(:pool, pool)
    end

    {:noreply, state}
  end

  defp scan_txs(%{tx_data: tx_data}) do
    with {:ok, decoded} <- Jason.decode(tx_data) do
      scan_tx(decoded)
    end
  end

  defp scan_tx(%{"messages" => messages}) do
    Enum.reduce(messages, [], fn
      %{
        "@type" => "/types.MsgObservedTxQuorum",
        "quoTx" => %{"obsTx" => %{"tx" => %{"id" => id}}}
      },
      acc ->
        [id | acc]

      _, acc ->
        acc
    end)
  end

  defp scan_tx(_), do: []

  defp scan_event(%{
         attributes: [
           %{key: "pool", value: pool},
           %{key: "type", value: _},
           %{key: "rune_address", value: rune_address},
           %{key: "rune_amount", value: _rune_amount},
           %{key: "asset_amount", value: _asset_amount},
           %{key: "asset_address", value: asset_address}
           | _
         ],
         type: "pending_liquidity"
       }) do
    [{pool, rune_address}, {pool, asset_address}]
  end

  defp scan_event(%{
         attributes: [
           %{key: "pool", value: pool},
           %{key: "liquidity_provider_units", value: _},
           %{key: "rune_address", value: rune_address},
           %{key: "rune_amount", value: _rune_amount},
           %{key: "asset_amount", value: _asset_amount},
           %{key: "asset_address", value: asset_address}
           | _
         ],
         type: "add_liquidity"
       }) do
    [{pool, rune_address}, {pool, asset_address}]
  end

  defp scan_event(%{
         attributes: [%{key: "pool", value: pool} | _],
         type: "withdraw"
       }) do
    [{pool, :_}]
  end

  defp scan_event(_), do: []
end
