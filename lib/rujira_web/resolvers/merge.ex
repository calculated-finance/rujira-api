defmodule RujiraWeb.Resolvers.Merge do
  @moduledoc """
  Handles GraphQL resolution for Merge Protocol-related queries.
  """
  alias Absinthe.Resolution.Helpers
  alias Rujira.Merge.Pool

  def node(%{address: address}, _, _) do
    Helpers.async(fn ->
      Rujira.Merge.get_pool(address)
    end)
  end

  def status(%Pool{} = pool, _, _) do
    Helpers.async(fn ->
      with {:ok, %{status: status}} <- Rujira.Merge.load_pool(pool) do
        {:ok, status}
      end
    end)
  end

  def resolver(_, _, _) do
    Helpers.async(&Rujira.Merge.load_pools/0)
  end

  def account(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, accounts} <- Rujira.Merge.load_accounts(address) do
        {:ok,
         %{
           total_size: Enum.reduce(accounts, 0, fn e, a -> e.size + a end),
           accounts: accounts
         }}
      end
    end)
  end
end
