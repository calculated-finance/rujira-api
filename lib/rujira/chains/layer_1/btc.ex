defmodule Rujira.Chains.Layer1.Btc do
  defstruct []
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Btc do
  def balances(_a, address) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("bitcoin", address, 8) do
      {:ok, [%{amount: balance, asset: "BTC.BTC"}]}
    end
  end
end
