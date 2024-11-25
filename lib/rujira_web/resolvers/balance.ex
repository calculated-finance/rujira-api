defmodule RujiraWeb.Resolvers.Balance do
  def cosmos(%{address: address, chain: chain}, _, _) do
    Rujira.Balances.cosmos_balances(chain, address)
  end

  def native(%{address: address, chain: chain}, _, _) do
    Rujira.Balances.native_balances(chain, address)
  end

  def metadata(%{asset: asset}, _, _) do
    symbol = Rujira.Assets.to_symbol(asset)
    decimals = Rujira.Assets.decimals(asset)
    {:ok, %{symbol: symbol, decimals: decimals}}
  end

  def metadata(%{denom: _denom}, _, _) do
    {:ok, %{current: 1000, change_day: 0.1}}
  end

  def price(%{asset: asset}, _, _) do
    symbol = Rujira.Assets.to_symbol(asset)

    with {:ok, %{price: price, change: change}} <- Rujira.Prices.get(symbol) do
      {:ok, %{current: price, change_day: change}}
    end
  end

  def price(%{denom: _denom}, _, _) do
    {:ok, %{current: 1000, change_day: 0.1}}
  end
end
