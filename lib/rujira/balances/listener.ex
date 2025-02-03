defmodule Rujira.Balances.Listener do
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

      # TODO: Not happy with the Rujira app needing to know the graphql id schema.
      id = "account:thor:#{a}"
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, id, node: id)
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
end
