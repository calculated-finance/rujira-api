defmodule RujiraWeb.Resolvers.Balance do
  def cosmos(%{address: address, chain: chain}, _, _) do
    Rujira.Balances.cosmos_balances(chain, address)
  end

  def native(%{address: address, chain: chain}, _, _) do
    Rujira.Balances.native_balances(chain, address)
  end

  def quote(%{request: %{to_asset: asset}, expected_amount_out: amount}, _, _) do
    {:ok, %{asset: asset, amount: amount}}
  end
end
