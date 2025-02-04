defmodule Rujira.Chains.Bch do
  defstruct []
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Bch do
  alias Rujira.Assets

  def balances(_a, address, _assets) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("bitcoin-cash", address, 8) do
      {:ok, [%{amount: balance, asset: Assets.from_string("BCH.BCH")}]}
    end
  end
end
