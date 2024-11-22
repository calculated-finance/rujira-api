defmodule Rujira.Balances do
  def fetch_balances(:thor, address) do
    Rujira.Balances.Thor.fetch_balances(address)
  end

  def fetch_balances(:avax, address) do
    Rujira.Balances.Evm.fetch_balances(:avax, address)
  end

  def fetch_balances(:bch, _) do
    {:ok, [%{amount: 1_000_000_000, asset: "BCH.BCH"}]}
  end

  def fetch_balances(:bsc, _) do
    {:ok, [%{amount: 1_000_000_000_000_000_000, asset: "BNB.BNB"}]}
  end

  def fetch_balances(:btc, address) do
    Rujira.Balances.Btc.fetch_balances(address)
  end

  def fetch_balances(:doge, _) do
    {:ok, [%{amount: 1_000_000_000, asset: "DOGE.DOGE"}]}
  end

  def fetch_balances(:eth, address) do
    Rujira.Balances.Evm.fetch_balances(:eth, address)
  end

  def fetch_balances(:gaia, address) do
    Rujira.Balances.Gaia.fetch_balances(address)
  end

  def fetch_balances(:kuji, _) do
    {:ok, [%{amount: 1_000_000, asset: "KUJI.KUJI"}]}
  end

  def fetch_balances(:ltc, _) do
    {:ok, [%{amount: 100_000_000, asset: "LTC.LTC"}]}
  end
end
