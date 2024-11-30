defmodule RujiraWeb.Resolvers.Balance do
  def cosmos(%{address: address, chain: chain}, _, _) do
    Rujira.Balances.cosmos_balances(chain, address)
  end

  def asset(%{asset: asset}, _, _) do
    {:ok, %{asset: asset}}
  end

  def denom(%{denom: denom}, _, _) do
    {:ok, %{denom: denom}}
  end

  def native(%{address: address, chain: chain}, _, _) do
    Rujira.Balances.native_balances(chain, address)
  end

  def metadata(%{asset: asset}, _, _) do
    symbol = Rujira.Assets.symbol(asset)
    decimals = Rujira.Assets.decimals(asset)
    {:ok, %{symbol: symbol, decimals: decimals}}
  end

  def metadata(%{denom: denom}, _, _) do
    symbol = Rujira.Tokens.symbol(denom)
    decimals = Rujira.Tokens.decimals(denom)
    {:ok, %{symbol: symbol, decimals: decimals}}
  end

  def price(%{asset: asset}, _, _) do
    symbol = Rujira.Assets.symbol(asset)

    with {:ok, %{price: price, change: change}} <- Rujira.Prices.get(symbol) do
      {:ok, %{current: price, change_day: change}}
    end
  end

  def price(%{denom: denom}, _, _) do
    symbol = Rujira.Tokens.symbol(denom)

    with {:ok, %{price: price, change: change}} <- Rujira.Prices.get(symbol) do
      {:ok, %{current: price, change_day: change}}
    end
  end

  def quote(%{request: %{to_asset: asset}, expected_amount_out: amount}, _, _) do
    {:ok, %{asset: asset, amount: amount}}
  end
end
