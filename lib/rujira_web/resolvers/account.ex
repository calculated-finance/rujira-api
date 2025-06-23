defmodule RujiraWeb.Resolvers.Account do
  @moduledoc """
  Handles GraphQL resolution for account-related queries.

  Provides functions to resolve account data, including address translation
  and chain information for both single and multiple account lookups.
  """
  alias RujiraWeb.Resolvers.Node

  def resolver(%{chain: chain}, %{addresses: addresses}, _) do
    {:ok, Enum.map(addresses, &%{address: &1, chain: chain})}
  end

  def resolver(%{address: address, chain: chain}, %{}, _) do
    with {:ok, address} <- Rujira.Accounts.translate_address(address) do
      {:ok, %{id: Node.encode_id(:account, address), address: address, chain: chain}}
    end
  end
end
