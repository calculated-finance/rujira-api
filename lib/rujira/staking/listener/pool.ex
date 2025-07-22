defmodule Rujira.Staking.Listener.Pool do
  @moduledoc """
  Listens for and processes staking-related blockchain events.

  Handles block transactions to detect staking events, updates cached data,
  and publishes real-time updates through the events system.
  """

  alias Rujira.Chains.Thor
  alias Rujira.Staking
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{txs: txs}, state) do
    scan_txs(txs, state)
    {:noreply, state}
  end

  defp scan_txs(txs, state) do
    events =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)

    transfers =
      events
      |> Enum.map(&scan_token_transfer(&1, state))
      |> Enum.reject(&is_nil/1)
      |> Rujira.Enum.uniq()

    # Any execution will invalidate every account
    for owner <- Enum.flat_map(events, &scan_contract_execution(&1, state)) do
      Logger.debug("#{__MODULE__} execution #{state.address}")
      Memoize.invalidate(Staking, :query_account, [state.address, :_])
      Memoize.invalidate(Staking, :query_pool, [state.address])
      Memoize.invalidate(Thor, :balance_of, [owner, state.receipt_denom])
      Rujira.Events.publish_node(:staking_status, state.address)
      Rujira.Events.publish(%{contract: state.address}, staking_account_updated: "*")
    end

    for owner <- transfers do
      # We catch staking events above, so this is only concerned with balance transfers
      # of the LST va MsgSend etc, which will only affect an account
      Memoize.invalidate(Thor, :balance_of, [owner, state.receipt_denom])
      Rujira.Events.publish_node(:staking_account, "#{state.address}/#{owner}")
    end
  end

  def scan_contract_execution(
        %{
          attributes: %{"_contract_address" => contract} = attributes,
          type: "wasm-rujira-staking/" <> _
        },
        %{address: address}
      )
      when contract == address,
      do: [Map.get(attributes, "owner")]

  def scan_contract_execution(_, _), do: []

  defp scan_token_transfer(
         %{
           attributes: %{"recipient" => recipient, "sender" => sender, "amount" => amount},
           type: "transfer"
         },
         %{receipt_denom: receipt_denom}
       ) do
    amount
    |> String.split(",")
    |> Enum.map(&String.replace(&1, ~r/^[0-9]+/, ""))
    |> Enum.reduce([], fn
      denom, acc when denom == receipt_denom ->
        [sender, recipient | acc]

      _, acc ->
        acc
    end)
  end

  defp scan_token_transfer(_, _), do: nil
end
