defmodule RujiraWeb.Resolvers.Account do
  def resolver(%{chain: chain}, %{addresses: addresses}, _) do
    {:ok, Enum.map(addresses, &%{address: &1, chain: chain})}
  end
end
