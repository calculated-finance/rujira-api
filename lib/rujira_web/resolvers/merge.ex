defmodule RujiraWeb.Resolvers.Merge do
  def node(%{address: address}, _, _) do
    with {:ok, pool} <- Rujira.Merge.get_pool(address),
         {:ok, pool} <- Rujira.Merge.load_pool(pool) do
      {:ok, put_id(pool)}
    end
  end

  def resolver(_, _, _) do
    with {:ok, res} <- Rujira.Merge.load_pools() do
      res
      |> Enum.map(&put_id/1)
      |> then(&{:ok, &1})
    end
  end

  def account(%{address: address}, _, _) do
    with {:ok, accounts} <- Rujira.Merge.load_accounts(address) do
      {:ok,
       %{
         total_size: Enum.reduce(accounts, 0, fn e, a -> e.size + a end),
         accounts: accounts
       }}
    end
  end

  defp put_id(%{address: address} = pool) do
    %{pool | id: RujiraWeb.Resolvers.Node.encode_id(:contract, :merge, address)}
  end
end
