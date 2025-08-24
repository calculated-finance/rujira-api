defmodule Thorchain.Listener do
  @moduledoc """
  Listens for and processes Thorchain-related blockchain events.

  Handles block transactions to detect Thorchain activities, updates cached data,
  and publishes real-time updates through the events system.

  """
  require Logger
  use Thornode.Observer

  @impl true
  def handle_new_block(%{header: %{height: height}, txs: txs}, state) do
    Memoize.invalidate(Thorchain, :inbound_addresses)
    Memoize.invalidate(Thorchain, :outbound_fees)
    Memoize.invalidate(Thorchain, :pools)
    Memoize.invalidate(Thorchain, :pool)

    # Invalidate block at this height in case an error response has been cached from a previous request
    Memoize.invalidate(Thorchain, :block, [height])

    hashes =
      txs
      |> Enum.flat_map(&scan_txs/1)
      |> Rujira.Enum.uniq()

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

    for {pool, address} <- events |> Enum.flat_map(&scan_event/1) |> Rujira.Enum.uniq() do
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
         attributes: %{
           "pool" => pool,
           "rune_address" => rune_address,
           "asset_address" => asset_address
         },
         type: "pending_liquidity"
       }) do
    [{pool, rune_address}, {pool, asset_address}]
  end

  defp scan_event(%{
         attributes: %{
           "pool" => pool,
           "rune_address" => rune_address,
           "asset_address" => asset_address
         },
         type: "add_liquidity"
       }) do
    [{pool, rune_address}, {pool, asset_address}]
  end

  defp scan_event(%{attributes: %{"pool" => pool}, type: "withdraw"}) do
    [{pool, :_}]
  end

  defp scan_event(_), do: []
end
