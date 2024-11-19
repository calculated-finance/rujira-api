defmodule RujiraWeb.Resolvers.Account do
  def resolver(_, _, _) do
    {:ok,
     %{
       address: "thor1htrqlgcqc8lexctrx7c2kppq4vnphkatgaj932",
       balances: [
         %{denom: "btc-btc", amount: 100_000_000},
         %{denom: "x/uruji", amount: 1_000_000},
         %{denom: "rune", amount: 1_000_000},
         %{denom: "gaia-kuji", amount: 1_000_000}
       ]
     }}
  end

  def avax_resolver(%{address: "0x" <> _}, _, _resolution) do
    {:ok, %{balance: %{amount: 1_000_000_000_000_000_000, asset: "AVAX.AVAX"}}}
  end

  def avax_resolver(_, _, _resolution) do
    {:error, :invalid_address}
  end

  def btc_resolver(%{address: "bc1" <> _}, _, _resolution) do
    {:ok, %{balance: %{amount: 100_000_000, asset: "BTC.BTC"}}}
  end

  def btc_resolver(_, _, _resolution) do
    {:error, :invalid_address}
  end

  def bch_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: %{amount: 1_000_000_000, asset: "BCH.BCH"}}}
  end

  def bsc_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: %{amount: 1_000_000_000_000_000_000, asset: "BNB.BNB"}}}
  end

  def doge_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: %{amount: 1_000_000_000, asset: "DOGE.DOGE"}}}
  end

  def eth_resolver(%{address: "0x" <> _}, _, _resolution) do
    {:ok, %{balance: %{amount: 1_000_000_000_000_000_000, asset: "ETH.ETH"}}}
  end

  def eth_resolver(_, _, _resolution) do
    {:error, :invalid_address}
  end

  def gaia_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: %{amount: 1_000_000, asset: "GAIA.ATOM"}}}
  end

  def kuji_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: %{amount: 1_000_000, asset: "GAIA.KUJI"}}}
  end

  def ltc_resolver(%{address: _address}, _, _resolution) do
    {:ok, %{balance: %{amount: 100_000_000, asset: "LTC.LTC"}}}
  end

  def thor_resolver(%{address: "thor1" <> _}, _, _resolution) do
    {:ok, %{balance: %{amount: 1_000_000, asset: "THOR.RUNE"}}}
  end

  def thor_resolver(_, _, _resolution) do
    {:error, :invalid_address}
  end

  def root_resolver(_, %{addresses: addresses}, _) do
    {:ok, Enum.map(addresses, &%{address: &1})}
  end
end
