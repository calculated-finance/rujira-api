defmodule RujiraWeb.Resolvers.Merge do
  def node(%{address: address}, _, _) do
    with {:ok, pool} <- Rujira.Merge.get_pool(address),
         {:ok, pool} <- Rujira.Merge.load_pool(pool) do
      pool = Rujira.Merge.Service.set_values(pool)
      {:ok, %{pool | id: RujiraWeb.Resolvers.Node.encode_id(:contract, :merge, address)}}
    end
  end

  def merge_stats(_, _, _) do
    with {:ok, res} <- Rujira.Merge.Service.get_stats() do
      {:ok, Rujira.Merge.Service.get_rates(res)}
    end
  end

  def account_stats(%{address: address}, _, _) do
    with {:ok, accounts_pools} <- Rujira.Merge.Service.get_accounts(address),
         {:ok, stats} <- Rujira.Merge.Service.account_stats(accounts_pools) do
      {:ok, stats}
    end
  end
end
