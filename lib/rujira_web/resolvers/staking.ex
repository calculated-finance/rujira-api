defmodule RujiraWeb.Resolvers.Staking do
  @moduledoc """
  Handles GraphQL queries for the Staking module's functionality.
  """
  alias Absinthe.Resolution.Helpers
  alias Rujira.Assets
  alias Rujira.Prices
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
        {:ok, Map.put(status, :bond_denom, pool.bond_denom)}
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
      Rujira.Enum.reduce_while_ok(pools, [], fn x ->
        case Staking.load_account(x, address) do
          {:ok, %{bonded: 0}} -> :skip
          other -> other
        end
      end)
    end
  end

  def value_usd(
        %{
          pending_revenue: pending_revenue,
          liquid_size: liquid_size,
          bonded: bonded,
          pool: %{bond_denom: bond_denom, revenue_denom: revenue_denom}
        },
        _,
        _
      ) do
    with {:ok, bond_asset} <- Assets.from_denom(bond_denom),
         {:ok, revenue_asset} <- Assets.from_denom(revenue_denom) do
      {:ok,
       Prices.value_usd(bond_asset.ticker, bonded + liquid_size) +
         Prices.value_usd(revenue_asset.ticker, pending_revenue)}
    end
  end

  def value_usd(
        %{
          bond_denom: bond_denom,
          account_bond: account_bond,
          liquid_bond_size: liquid_bond_size
        },
        _,
        _
      ) do
    with {:ok, bond_asset} <- Assets.from_denom(bond_denom) do
      {:ok, Prices.value_usd(bond_asset.ticker, account_bond + liquid_bond_size)}
    end
  end

  def summary(pool, _, _) do
    Helpers.async(fn ->
      Pool.summary(pool)
    end)
  end

  def pending_balances(_, _, _) do
    Helpers.async(fn ->
      {:ok, Staking.converter_balances()}
    end)
  end
end
