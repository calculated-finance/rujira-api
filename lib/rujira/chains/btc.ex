defmodule Rujira.Chains.Btc do
  def balances(address, _assets) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("bitcoin", address, 8) do
      {:ok, [%{amount: balance, asset: Assets.from_string("BTC.BTC")}]}
    end
  end
end
