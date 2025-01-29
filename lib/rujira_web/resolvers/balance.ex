defmodule RujiraWeb.Resolvers.Balance do
  alias Absinthe.Resolution.Helpers

  def resolver(%{address: address, chain: chain}, _, _) do
    Helpers.async(fn ->
      Rujira.Balances.balances(chain, address)
    end)
  end
end
