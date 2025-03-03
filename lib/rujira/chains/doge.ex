defmodule Rujira.Chains.Doge do
  alias Rujira.Assets

  def balances(address, _assets) do
    with {:ok, balance} <- CryptoApis.Api.get_balance("dogecoin", address, 8) do
      {:ok, [%{amount: balance, asset: Assets.from_string("DOGE.DOGE")}]}
    end
  end
end
