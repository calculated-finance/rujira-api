defmodule RujiraWeb.Resolvers.Balance do
  @moduledoc """
  Handles GraphQL resolution for blockchain balance-related queries.
  """
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

  def parse(amount) when is_binary(amount) do
    with {amount, ""} <- Integer.parse(amount) do
      {:ok, amount}
    end
  end

  def parse(amount) when is_integer(amount), do: {:ok, amount}
end
