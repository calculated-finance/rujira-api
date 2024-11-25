defmodule RujiraWeb.Resolvers.Account do
  def resolver(%{chain: chain}, %{addresses: addresses}, _) do
    {:ok, Enum.map(addresses, &%{address: &1, chain: chain})}
  end

  def resolver(%{address: address, chain: :thor}, %{}, _) do
    {:ok, %{address: address, chain: :thor}}
  end

  # Kujira has a special case as an unsupported L1 (and so no app layer deposits) so that the UIs
  # can fetch merge token balances using the same schema
  def resolver(%{address: address, chain: :kuji}, %{}, _) do
    {:ok, %{address: address, chain: :kuji}}
  end

  def resolver(%{address: address, chain: chain}, %{}, _) do
    {:error, "mapping unavailble for #{address} on #{chain}"}
  end
end
