defmodule Rujira.Invalidator do
  alias Phoenix.PubSub
  use GenServer
  require Logger

  @impl true
  def init(opts) do
    PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")

    {:ok, opts}
  end

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def handle_info(%{txs: txs}, state) do
    txs
    |> Enum.flat_map(& &1["result"]["events"])
    |> scan_attributes()
    |> Enum.uniq()
    |> Enum.map(&invalidate/1)

    {:noreply, state}
  end

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{"_contract_address" => address}
           | rest
         ],
         collection
       ) do
    # Here we can just invalidate the address for all protocols.
    # Only the one where it actually matches the protocol will be affected
    scan_attributes(rest, [
      {Rujira.Contract, :query_state_all, [address]},
      {Rujira.Contract, :query_state_smart, [address, :_]} | collection
    ])
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection

  defp invalidate({module, function, args}) do
    Logger.debug("#{__MODULE__} invalidating #{module}.#{function} #{Enum.join(args, ",")}")
    Memoize.invalidate(module, function, args)
  end
end
