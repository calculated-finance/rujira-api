defmodule Rujira.Pilot.Indexer do
  @moduledoc """
  Listens for and indexes trading events from the Pilot protocol.

  This module implements the `Thornode.Observer` behavior to monitor and process
  blockchain events related to trading activity, extracting and storing trade data
  for pilot analysis and reporting.
  """
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(
        %{
          header: %{height: height, time: time},
          txs: txs
        },
        state
      ) do
    for {%{hash: txhash, result: %{events: events}}, tx_idx} <- Enum.with_index(txs) do
      scan_events(height, txhash, tx_idx, events, time)
    end

    {:noreply, state}
  end

  defp scan_events(height, txhash, tx_idx, events, time) do
    events
    |> Enum.map(&scan_bid_actions/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.with_index()
    |> Enum.map(fn {bid, idx} ->
      Map.merge(bid, %{
        height: height,
        tx_idx: tx_idx,
        idx: idx,
        txhash: txhash,
        timestamp: time
      })
    end)
    |> Rujira.Pilot.insert_bid_actions()
  end

  defp scan_bid_actions(%{
         attributes: %{
           "_contract_address" => contract_address,
           "owner" => owner,
           "premium" => premium,
           "amount" => amount
         },
         type: "wasm-rujira-pilot/order." <> type
       }) do
    insert_bid_action(contract_address, premium, amount, owner, type)
  end

  defp scan_bid_actions(%{
         attributes: %{
           "_contract_address" => contract_address,
           "owner" => owner,
           "premium" => premium,
           "offer" => offer
         },
         type: "wasm-rujira-pilot/order." <> type
       }) do
    insert_bid_action(contract_address, premium, offer, owner, type)
  end

  defp scan_bid_actions(_), do: nil

  defp insert_bid_action(contract_address, premium, amount, owner, type) do
    with {premium, _} <- Integer.parse(premium),
         {amount, _} <- Integer.parse(amount) do
      %{
        contract: contract_address,
        premium: premium,
        amount: amount,
        owner: owner,
        type: String.to_atom(type)
      }
    end
  end
end
