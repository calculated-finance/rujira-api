defmodule RujiraWeb.Resolvers.Merge do
  def merge_stats(_, _, _) do
    with {:ok, res} <- Rujira.Merge.Service.get_stats(),
         {:ok, res} <- Rujira.Merge.Service.get_rates(res) do
      {:ok, res}
    end
  end

  def account_stats(%{address: address}, _, _) do
    with {:ok, accounts_pools} <- Rujira.Merge.Service.get_accounts(address),
         {:ok, stats} <- Rujira.Merge.Service.account_stats(accounts_pools) do
      {:ok, stats}
    end
  end
end
