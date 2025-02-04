defmodule Rujira.Chains.Ltc do
  defstruct []
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Ltc do
  alias Rujira.Assets

  def balances(_a, address, _assets) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("litecoin", address, 8) do
      {:ok, [%{amount: balance, asset: Assets.from_string("LTC.LTC")}]}
    end
  end
end
