defmodule RujiraWeb.Resolvers.Staking do
  alias Absinthe.Resolution.Helpers

  def node(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, pool} <- Rujira.Staking.get_pool(address),
           {:ok, pool} <- Rujira.Staking.load_pool(pool) do
        {:ok, put_id(pool)}
      end
    end)
  end

  def resolver(_, _, _) do
    Helpers.async(fn ->
      with {:ok, res} <- Rujira.Staking.load_pools() do
        res
        |> Enum.map(&put_id/1)
        |> then(&{:ok, &1})
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

  defp put_id(%{address: address} = pool) do
    %{pool | id: RujiraWeb.Resolvers.Node.encode_id(:contract, :staking, address)}
  end
end
