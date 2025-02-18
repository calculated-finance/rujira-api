defmodule Rujira.Bank.Supply do
  alias Rujira.Assets
  alias Cosmos.Bank.V1beta1.QuerySupplyOfResponse
  alias Cosmos.Bank.V1beta1.QuerySupplyOfRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Cosmos.Bank.V1beta1.QueryTotalSupplyRequest
  alias Cosmos.Bank.V1beta1.Query.Stub

  use GenServer
  require Logger

  defstruct [:id, :balance]

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
      {:ok,
       Enum.reduce(
         supply,
         %{},
         fn v, agg ->
           case Assets.from_denom(v.denom) do
             {:ok, asset} ->
               Map.put(agg, asset.id, %__MODULE__{
                 id: asset.id,
                 balance: %{
                   amount: v.amount,
                   asset: asset
                 }
               })

             _ ->
               agg
           end
         end
       )}
    end
  end

  @impl true
  def handle_info(
        %{txs: txs, begin_block_events: begin_block_events, end_block_events: end_block_events},
        state
      ) do
    events =
      txs
      |> Enum.flat_map(fn x ->
        case x["result"]["events"] do
          nil -> []
          xs when is_list(xs) -> xs
        end
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
    |> scan_events()
    |> IO.inspect()
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
