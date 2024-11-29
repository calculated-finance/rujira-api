defmodule Rujira.Chains.Layer1.Bch do
  defstruct []
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Bch do
  def balances(_a, address) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("bitcoin-cash", address, 8) do
      {:ok, [%{amount: balance, asset: "BCH.BCH"}]}
    end
  end
end
