defmodule RujiraWeb.Resolvers.Staking do
  alias Rujira.Staking.Pool
  alias Absinthe.Resolution.Helpers

  def node(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, pool} <- Rujira.Staking.get_pool(address) do
        {:ok, pool}
      end
    end)
  end

  def status(%Pool{} = pool, _, _) do
    Helpers.async(fn ->
      with {:ok, %{status: status}} <- Rujira.Staking.load_pool(pool) do
        {:ok, status}
      end
    end)
  end

  @spec resolver(any(), any(), any()) :: {:middleware, Absinthe.Middleware.Async, {any(), any()}}
  def resolver(_, _, _) do
    Helpers.async(fn ->
      with {:ok, res} <- Rujira.Staking.load_pools() do
        {:ok, res}
      end
    end)
  end

  def account(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, accounts} <- Rujira.Staking.load_accounts(address) do
        {:ok, accounts}
      end
    end)
  end

  def summary(%{address: address}, %{resolution: resolution}, _) do
    Helpers.async(fn ->
      with {:ok, summary} <- Rujira.Staking.get_summary(address, resolution) do
        {:ok, summary}
      end
    end)
  end
end
