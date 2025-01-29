defmodule Rujira.Chains.Doge do
  defstruct []
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Doge do
  def balances(_a, address, _assets) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("dogecoin", address, 8) do
      {:ok, [%{amount: balance, asset: "DOGE.DOGE"}]}
    end
  end
end
