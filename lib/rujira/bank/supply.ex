defmodule Rujira.Bank.Supply do
  alias Cosmos.Bank.V1beta1.QuerySupplyOfResponse
  alias Cosmos.Bank.V1beta1.QuerySupplyOfRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Cosmos.Bank.V1beta1.QueryTotalSupplyRequest
  alias Cosmos.Bank.V1beta1.Query.Stub

  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Phoenix.PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")

    with {:ok, %{supply: supply}} <-
           Thorchain.Node.stub(
             &Stub.total_supply/2,
             %QueryTotalSupplyRequest{pagination: %PageRequest{limit: 100}}
           ) do
      {:ok, Enum.reduce(supply, %{}, &Map.put(&2, &1.denom, &1.amount))}
    end
  end

  @impl true
  def handle_info(%{txs: txs}, state) do
    {:noreply, Map.merge(state, scan_txs(txs))}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  defp scan_txs(txs) do
    txs
    |> Enum.flat_map(fn x ->
      case x["result"]["events"] do
        nil -> []
        xs when is_list(xs) -> xs
      end
    end)
    |> scan_events()
    |> Enum.uniq()
    |> Enum.reduce(%{}, fn denom, acc ->
      case Thorchain.Node.stub(
             &Stub.supply_of/2,
             %QuerySupplyOfRequest{denom: denom}
           ) do
        {:ok, %QuerySupplyOfResponse{amount: %{amount: amount}}} ->
          Map.put(acc, denom, amount)

        _ ->
          acc
      end
    end)
  end

  defp scan_events(attributes, collection \\ [])

  defp scan_events(
         [%{"type" => "coinbase"} = event | rest],
         collection
       ) do
    scan_events(rest, [parse_token(event) | collection])
  end

  defp scan_events(
         [%{"type" => "burn"} = event | rest],
         collection
       ) do
    scan_events(rest, [parse_token(event) | collection])
  end

  defp scan_events([_ | rest], collection), do: scan_events(rest, collection)
  defp scan_events([], collection), do: collection

  defp parse_token(%{"amount" => amount}) do
    String.replace(amount, ~r/[0-9]+/, "")
  end
end
