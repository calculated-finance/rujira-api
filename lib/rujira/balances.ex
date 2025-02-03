defmodule Rujira.Balances do
  require Logger
  alias Rujira.Chains.Adapter
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(state) do
    Phoenix.PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")
    {:ok, state}
  end

  @impl true
  def handle_info(
        %{txs: txs, begin_block_events: begin_block_events, end_block_events: end_block_events},
        state
      ) do
    addresses =
      txs
      |> Enum.flat_map(& &1["result"]["events"])
      |> Enum.concat(begin_block_events)
      |> Enum.concat(end_block_events)
      |> scan_attributes()
      |> Enum.uniq()

    for a <- addresses do
      Logger.debug("#{__MODULE__} change #{a}")

      Absinthe.Subscription.publish(
        RujiraWeb.Endpoint,
        # Let the schema query and resolve the new data
        a,
        account_changed: a
      )
    end

    {:noreply, state}
  end

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{
             "type" => "transfer",
             "recipient" => recipient,
             "sender" => sender
           }
           | rest
         ],
         collection
       ) do
    scan_attributes(rest, [
      recipient,
      sender | collection
    ])
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection

  @doc """
  Fetches the balances of THORChain supported assets on native chains, with the correct Asset string for THORChain usage
  """
  @spec balances(atom(), String.t()) ::
          {:ok, list(%{asset: String.t(), amount: String.t()})} | {:error, any()}
  def balances(chain, address) do
    with {:ok, adapter} <- Rujira.Chains.get_native_adapter(chain),
         assets <- Rujira.Assets.erc20(chain) do
      Adapter.balances(adapter, address, assets)
    end
  end
end
