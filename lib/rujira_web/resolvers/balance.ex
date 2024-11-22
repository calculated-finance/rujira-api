defmodule RujiraWeb.Resolvers.Balance do
  def cosmos(%{address: address, chain: chain}, _, _) do
    Rujira.Balances.cosmos_balances(chain, address)
  end

  def native(%{address: address, chain: chain}, _, _) do
    Rujira.Balances.native_balances(chain, address)
  end
end
