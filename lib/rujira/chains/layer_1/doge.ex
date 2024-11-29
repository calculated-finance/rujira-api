defmodule Rujira.Chains.Layer1.Doge do
  defstruct []
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Doge do
  def balances(_a, address) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("dogecoin", address, 8) do
      {:ok, [%{amount: balance, asset: "DOGE.DOGE"}]}
    end
  end
end
