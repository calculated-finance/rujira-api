defmodule RujiraWeb.Resolvers.Balance do
  alias Absinthe.Resolution.Helpers

  def resolver(%{address: address, chain: chain}, _, _) do
    Helpers.async(fn ->
      with {:ok, balances} <- Rujira.Balances.balances(chain, address) do
        {:ok, Enum.map(balances, &Map.put(&1, :address, address))}
      end
    end)
  end

  def utxos(%{address: address, asset: %{chain: chain}}, _, _) do
    Helpers.async(fn ->
      chain
      |> String.downcase()
      |> String.to_existing_atom()
      |> Rujira.Balances.utxos(address)
    end)
  end
end
