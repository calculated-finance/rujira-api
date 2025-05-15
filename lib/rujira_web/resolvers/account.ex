defmodule RujiraWeb.Resolvers.Account do
  alias RujiraWeb.Resolvers.Node

  def resolver(%{chain: chain}, %{addresses: addresses}, _) do
    {:ok, Enum.map(addresses, &%{address: &1, chain: chain})}
  end

  def resolver(%{address: address, chain: :thor}, %{}, _) do
    {:ok, %{id: Node.encode_id(:account, address), address: address, chain: :thor}}
  end

  def resolver(%{address: address, chain: chain}, %{}, _) do
    {:error, "mapping unavailble for #{address} on #{chain}"}
  end
end
