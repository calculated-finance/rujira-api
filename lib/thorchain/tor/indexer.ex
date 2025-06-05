defmodule Thorchain.Tor.Indexer do
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
  def handle_info(%{header: %{time: time}}, state) do
    with {:ok, pools} <- Thorchain.pools(),
         {:ok, time} <- DateTime.from_naive(time, "Etc/UTC") do
      pools
      |> Enum.map(&{&1.asset.id, &1.asset_tor_price, time})
      |> Thorchain.Tor.update_candles()
    end

    {:noreply, state}
  end
end
