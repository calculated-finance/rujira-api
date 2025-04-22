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

  def single(_, _, _) do
    Helpers.async(fn ->
      with {:ok, pool} <- Rujira.Staking.get_pool(Rujira.Staking.single()) do
        {:ok, pool}
      end
    end)
  end

  def dual(_, _, _) do
    Helpers.async(fn ->
      with {:ok, pool} <- Rujira.Staking.get_pool(Rujira.Staking.dual()) do
        {:ok, pool}
      end
    end)
  end

  def revenue(_, _, _) do
    Helpers.async(fn ->
      with {:ok, converter} <- Rujira.Revenue.get_converter(Rujira.Revenue.protocol()) do
        {:ok, converter}
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

  def resolver(_, _, _) do
    {:ok, %{single: nil, dual: nil, revenue: nil}}
  end

  def accounts(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, single} <- Rujira.Staking.get_pool(Rujira.Staking.single()),
           {:ok, dual} <- Rujira.Staking.get_pool(Rujira.Staking.dual()),
           {:ok, single} <- Rujira.Staking.load_account(single, address),
           {:ok, dual} <- Rujira.Staking.load_account(dual, address) do
        {:ok, %{single: single, dual: dual}}
      end
    end)
  end

  def pending_revenue(
        %{bonded: bonded, pending_revenue: pending_revenue, pool: pool},
        _,
        _
      ) do
    with {:ok,
          %{
            revenue_denom: revenue_denom,
            status: %{
              account_bond: account_bond,
              liquid_bond_size: liquid_bond_size,
              pending_revenue: global_pending_revenue
            }
          }} <- Rujira.Staking.load_pool(pool) do
      # Contract current doesn't allocate global pending revnue to Account balance on Query,
      # which is does on a withdrawal.
      # Simulate distribution here: https://gitlab.com/thorchain/rujira/-/blob/main/contracts/rujira-staking/src/state.rs?ref_type=heads#L183
      # https://gitlab.com/thorchain/rujira/-/blob/main/contracts/rujira-staking/src/state.rs?ref_type=heads#L135-139

      accounts_allocation =
        Integer.floor_div(account_bond * global_pending_revenue, account_bond + liquid_bond_size)

      account_allocation = Integer.floor_div(accounts_allocation * bonded, account_bond)

      {:ok, %{amount: pending_revenue + account_allocation, denom: revenue_denom}}
    end
  end

  def summary(pool, _, _) do
    Helpers.async(fn ->
      {:ok,
       %{
         apr: [
           10000,
           10000,
           10000,
           10000,
           10000,
           10000,
           10000,
           10000,
           10000
         ],
         revenue1: Rujira.Staking.get_revenue(pool, 1),
         revenue7: Rujira.Staking.get_revenue(pool, 7),
         revenue30: Rujira.Staking.get_revenue(pool, 30)
       }}
    end)
  end
end
