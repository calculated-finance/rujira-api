defmodule Rujira.Chains.Native.Btc do
  defstruct []
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chains.Native.Btc do
  def balances(_a, address) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("bitcoin", address, 8) do
      {:ok, [%{amount: balance, asset: "BTC.BTC"}]}
    end
  end
end
