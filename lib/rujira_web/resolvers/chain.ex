defmodule RujiraWeb.Resolvers.Chain do
  def avax_resolver(%{address: "0x" <> _}, _, _resolution) do
    {:ok, %{balance: 1_000_000_000_000_000_000}}
  end

  def avax_resolver(_, _, _resolution) do
    {:error, :invalid_address}
  end

  def btc_resolver(%{address: "bc1" <> _}, _, _resolution) do
    {:ok, %{balance: 100_000_000}}
  end

  def btc_resolver(_, _, _resolution) do
    {:error, :invalid_address}
  end

  def bch_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: 1_000_000_000}}
  end

  def bsc_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: 1_000_000_000_000_000_000}}
  end

  def doge_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: 1_000_000_000}}
  end

  def eth_resolver(%{address: "0x" <> _}, _, _resolution) do
    {:ok, %{balance: 1_000_000_000_000_000_000}}
  end

  def eth_resolver(_, _, _resolution) do
    {:error, :invalid_address}
  end

  def gaia_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: 1_000_000}}
  end

  def kuji_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: 1_000_000}}
  end

  def ltc_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: 100_000_000}}
  end

  def thor_resolver(%{address: "thor1" <> _}, _, _resolution) do
    {:ok, %{balance: 1_000_000}}
  end

  def thor_resolver(_, _, _resolution) do
    {:error, :invalid_address}
  end
end
