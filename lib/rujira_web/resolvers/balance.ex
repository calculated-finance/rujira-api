defmodule RujiraWeb.Resolvers.Balance do
  alias Absinthe.Resolution.Helpers

  def cosmos(%{address: address, chain: chain}, _, _) do
    Helpers.async(fn ->
      Rujira.Balances.cosmos_balances(chain, address)
    end)
  end

  def native(%{address: address, chain: chain}, _, _) do
    Helpers.async(fn ->
      Rujira.Balances.native_balances(chain, address)
    end)
  end
end
