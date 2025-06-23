defmodule RujiraWeb.Resolvers.Staking do
  @moduledoc """
  Handles GraphQL queries for the Staking module's functionality.
  """
  alias Absinthe.Resolution.Helpers
  alias Rujira.Assets
  alias Rujira.Enum
  alias Rujira.Revenue
  alias Rujira.Staking
  alias Rujira.Staking.Pool

  def node(%{address: address}, _, _) do
    Helpers.async(fn ->
      Staking.get_pool(address)
    end)
  end

  def single(_, _, _) do
    Helpers.async(fn ->
      Staking.get_pool(Staking.single())
    end)
  end

  def dual(_, _, _) do
    Helpers.async(fn ->
      Staking.get_pool(Staking.dual())
    end)
  end

  def pools(_, _, _) do
    Helpers.async(fn ->
      Staking.list_pools()
    end)
  end

  def revenue(_, _, _) do
    Helpers.async(fn ->
      Revenue.get_converter(Revenue.protocol())
    end)
  end

  def status(%Pool{} = pool, _, _) do
    Helpers.async(fn ->
      with {:ok, %{status: status}} <- Staking.load_pool(pool) do
        {:ok, status}
      end
    end)
  end

  def resolver(_, _, _) do
    {:ok, %{single: nil, dual: nil, revenue: nil}}
  end

  def accounts(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, single} <- Staking.get_pool(Staking.single()),
           {:ok, dual} <- Staking.get_pool(Staking.dual()),
           {:ok, single} <- Staking.load_account(single, address),
           {:ok, dual} <- Staking.load_account(dual, address) do
        {:ok, %{single: single, dual: dual}}
      end
    end)
  end

  def all_accounts(%{address: address}, _, _) do
    with {:ok, pools} <- Staking.list_pools() do
      Enum.reduce_while_ok(pools, [], fn x ->
        case Staking.load_account(x, address) do
          {:ok, %{bonded: 0}} -> :skip
          other -> other
        end
      end)
    end
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
          }} <- Staking.load_pool(pool),
         {:ok, asset} <- Assets.from_denom(revenue_denom) do
      if account_bond == 0 do
        {:ok, %{amount: pending_revenue, asset: asset}}
      else
        # Contract current doesn't allocate global pending revnue to Account balance on Query,
        # which is does on a withdrawal.
        # Simulate distribution here: https://gitlab.com/thorchain/rujira/-/blob/main/contracts/rujira-staking/src/state.rs?ref_type=heads#L183
        # https://gitlab.com/thorchain/rujira/-/blob/main/contracts/rujira-staking/src/state.rs?ref_type=heads#L135-139

        accounts_allocation =
          Integer.floor_div(
            account_bond * global_pending_revenue,
            account_bond + liquid_bond_size
          )

        account_allocation = Integer.floor_div(accounts_allocation * bonded, account_bond)

        {:ok, %{amount: pending_revenue + account_allocation, asset: asset}}
      end
    end
  end

  def summary(pool, _, _) do
    Helpers.async(fn ->
      Pool.summary(pool)
    end)
  end
end
