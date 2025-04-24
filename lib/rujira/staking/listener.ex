defmodule Rujira.Staking.Listener do
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
    scan_txs(txs)
    {:noreply, state}
  end

  defp scan_txs(txs) do
    events =
      txs
      |> Enum.flat_map(fn x ->
        case x["result"]["events"] do
          nil -> []
          xs when is_list(xs) -> xs
        end
      end)

    executions = events |> scan_executions() |> Enum.uniq() |> IO.inspect()
    transfers = events |> scan_transfers() |> Enum.uniq()

    for {a, o} <- executions do
      Logger.debug("#{__MODULE__} execution #{a}")

      id = Absinthe.Relay.Node.to_global_id(:staking_status, a, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)

      id = Absinthe.Relay.Node.to_global_id(:staking_account, "#{a}/#{o}", RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end

    for a <- transfers do
      Logger.debug("#{__MODULE__} transfer #{a}")

      # We can indiscriminately publish all transfer events over the :staking_summary
      # subscription.
      # Most will be ignored unless the specific subscription is requested
      id = Absinthe.Relay.Node.to_global_id(:staking_summary, a, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end
  end

  defp scan_executions(attributes, collection \\ [])

  defp scan_executions(
         [%{"type" => "wasm-rujira-staking/" <> _} = event | rest],
         collection
       ) do
    address = Map.get(event, "_contract_address")
    owner = Map.get(event, "owner")

    scan_executions(rest, [{address, owner} | collection])
  end

  defp scan_executions([_ | rest], collection), do: scan_executions(rest, collection)
  defp scan_executions([], collection), do: collection

  defp scan_transfers(attributes, collection \\ [])

  defp scan_transfers(
         [
           %{
             "amount" => _,
             "recipient" => recipient,
             "sender" => _,
             "type" => "transfer"
           }
           | rest
         ],
         collection
       ) do
    scan_transfers(rest, [recipient | collection])
  end

  defp scan_transfers([_ | rest], collection), do: scan_transfers(rest, collection)
  defp scan_transfers([], collection), do: collection
end
