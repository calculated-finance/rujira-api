defmodule Rujira.Balances do
  def fetch_balances(:thor, _) do
    {:ok,
     [
       %{denom: "btc-btc", amount: 100_000_000},
       %{denom: "x/uruji", amount: 1_000_000},
       %{denom: "rune", amount: 1_000_000},
       %{denom: "gaia-kuji", amount: 1_000_000}
     ]}
  end

  def fetch_balances(:avax, _) do
    {:ok, [%{amount: 1_000_000_000_000_000_000, asset: "AVAX.AVAX"}]}
  end

  def fetch_balances(:btc, _) do
    {:ok, [%{amount: 100_000_000, asset: "BTC.BTC"}]}
  end

  def fetch_balances(:bch, _) do
    {:ok, [%{amount: 1_000_000_000, asset: "BCH.BCH"}]}
  end

  def fetch_balances(:bsc, _) do
    {:ok, [%{amount: 1_000_000_000_000_000_000, asset: "BNB.BNB"}]}
  end

  def fetch_balances(:doge, _) do
    {:ok, [%{amount: 1_000_000_000, asset: "DOGE.DOGE"}]}
  end

  def fetch_balances(:eth, _) do
    {:ok, [%{amount: 1_000_000_000_000_000_000, asset: "ETH.ETH"}]}
  end

  def fetch_balances(:gaia, _) do
    {:ok, [%{amount: 1_000_000, asset: "GAIA.ATOM"}]}
  end

  def fetch_balances(:kuji, _) do
    {:ok, [%{amount: 1_000_000, asset: "GAIA.KUJI"}]}
  end

  def fetch_balances(:ltc, _) do
    {:ok, [%{amount: 100_000_000, asset: "LTC.LTC"}]}
  end
end
