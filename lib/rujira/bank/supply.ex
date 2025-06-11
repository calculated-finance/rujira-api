defmodule Rujira.Bank.Supply do
  alias Cosmos.Bank.V1beta1.QuerySupplyOfResponse
  alias Cosmos.Bank.V1beta1.QuerySupplyOfRequest
  alias Cosmos.Bank.V1beta1.Query.Stub

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
    |> Enum.uniq()
    |> Enum.reduce(%{}, fn denom, acc ->
      case Thorchain.Node.stub(
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

  def scan_event(%{attributes: attributes, type: "coinbase"}) do
    scan_attributes(attributes)
  end

  def scan_event(%{attributes: attributes, type: "burn"}) do
    scan_attributes(attributes)
  end

  def scan_event(_), do: []

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{value: amount, key: "amount"}
           | rest
         ],
         collection
       ) do
    scan_attributes(rest, [String.replace(amount, ~r/[0-9]+/, "") | collection])
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection
end
