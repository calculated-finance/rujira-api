defmodule Thorchain.Tor.Indexer do
  @moduledoc """
  Indexer module for processing Thorchain Asset prices.

  This module implements the `Thornode.Observer` behavior to index and store
  TOR prices from the Thorchain network.
  """
  use Thornode.Observer
  require Logger

  @impl true
  def handle_new_block(%{header: %{height: height, time: time}}, state) do
    with {:ok, pools} <- Thorchain.pools(height),
         {:ok, time} <- DateTime.from_naive(time, "Etc/UTC"),
         {:ok, rune} <- rune_price() do
      pools
      |> Enum.map(&{&1.asset.id, &1.asset_tor_price, time})
      |> Enum.concat([{"THOR.RUNE", rune, time}])
      |> Thorchain.Tor.update_candles()
    end

    {:noreply, state}
  end

  def rune_price() do
    with {:ok, %{rune_price_in_tor: price}} <- Thorchain.network() do
      {:ok, String.to_integer(price)}
    end
  end
end
