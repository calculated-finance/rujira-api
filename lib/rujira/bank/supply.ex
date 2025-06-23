defmodule Rujira.Bank.Supply do
  @moduledoc """
  Listens for token minting and burning events and tracks token supplies.

  This module implements the `Thornode.Observer` behavior to monitor and process
  blockchain events, maintaining an up-to-date view of token supplies across the network.
  """
  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QuerySupplyOfRequest
  alias Cosmos.Bank.V1beta1.QuerySupplyOfResponse

  use Thornode.Observer
  require Logger

  defstruct [:id, :balance]

  @impl true
  def handle_new_block(
        %{txs: txs, begin_block_events: begin_block_events, end_block_events: end_block_events},
        state
      ) do
    events =
      txs
      |> Enum.flat_map(fn
        %{result: %{events: xs}} when is_list(xs) -> xs
        _ -> []
      end)
      |> Enum.concat(begin_block_events)
      |> Enum.concat(end_block_events)

    {:noreply, Map.merge(state, handle_events(events))}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  defp handle_events(events) do
    events
    |> Enum.flat_map(&scan_event/1)
    |> Rujira.Enum.uniq()
    |> Enum.reduce(%{}, fn denom, acc ->
      case Thornode.query(
             &Stub.supply_of/2,
             %QuerySupplyOfRequest{denom: denom}
           ) do
        {:ok, %QuerySupplyOfResponse{amount: %{amount: amount}}} ->
          Logger.debug("#{__MODULE__} change #{denom}")

          Map.put(acc, denom, amount)

        _ ->
          acc
      end
    end)
  end

  def scan_event(%{attributes: %{"amount" => amount}, type: type})
      when type in ["coinbase", "burn"],
      do: [String.replace(amount, ~r/[0-9]+/, "")]

  def scan_event(_), do: []
end
