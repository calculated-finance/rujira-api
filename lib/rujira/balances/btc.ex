defmodule Rujira.Balances.Btc do
  def fetch_balances(address) do
    with {:ok, balance} <- Rujira.Blockstream.Api.get_balance(address) do
      {:ok, [%{amount: balance, asset: "BTC.BTC"}]}
    end
  end
end
