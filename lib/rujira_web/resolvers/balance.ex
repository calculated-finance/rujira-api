defmodule RujiraWeb.Resolvers.Balance do
  def resolver(%{address: address, chain: chain}, _, _) do
    Rujira.Balances.fetch_balances(chain, address)
  end
end
