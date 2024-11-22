defmodule Rujira.Chains.Native.Ltc do
  defstruct []
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chains.Native.Ltc do
  def balances(_a, address) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("litecoin", address, 8) do
      {:ok, [%{amount: balance, asset: "LTC.LTC"}]}
    end
  end
end
