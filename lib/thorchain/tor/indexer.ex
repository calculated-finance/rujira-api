defmodule Thorchain.Tor.Indexer do
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{header: %{height: height, time: time}}, state) do
    with {:ok, pools} <- Thorchain.pools(height),
         {:ok, time} <- DateTime.from_naive(time, "Etc/UTC") do
      pools
      |> Enum.map(&{&1.asset.id, &1.asset_tor_price, time})
      |> Thorchain.Tor.update_candles()
    end

    {:noreply, state}
  end
end
