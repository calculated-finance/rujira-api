defmodule Rujira.Chains.Gaia.Balances.Listener do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(state) do
    Phoenix.PubSub.subscribe(Rujira.PubSub, "gaia/tendermint/event/NewBlock")
    {:ok, state}
  end

  @impl true
  def handle_info(
        %{result_finalize_block: %{events: events}},
        state
      ) do
    addresses =
      events
      |> Enum.flat_map(&scan_event/1)
      |> Enum.uniq()

    for a <- addresses do
      Logger.debug("#{__MODULE__} change #{a}")

      id =
        Absinthe.Relay.Node.to_global_id(:layer_1_account, "gaia:#{a}", RujiraWeb.Schema)

      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end

    {:noreply, state}
  end

  defp scan_event(%{attributes: attributes, type: "transfer"}) do
    scan_attributes(attributes)
  end

  defp scan_event(_), do: []

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{value: recipient, key: "recipient"},
           %{value: sender, key: "sender"}
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
