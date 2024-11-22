defmodule Rujira.Chains.Cosmos.Kujira do
  def balances(_address) do
    {:ok, [%{amount: 1_000_000, asset: "KUJI.KUJI"}]}
  end
end
