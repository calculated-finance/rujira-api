defmodule Rujira.Chains.Ltc do
  alias Rujira.Assets

  def balances(address, _assets) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("litecoin", address, 8) do
      {:ok, [%{amount: balance, asset: Assets.from_string("LTC.LTC")}]}
    end
  end
end
