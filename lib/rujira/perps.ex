defmodule Rujira.Perps do
  @moduledoc """
  Rujira Perps by Levana.
  """

  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Perps.Account
  alias Rujira.Perps.Pool
  use Memoize

  @spec list_pools() ::
          {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def list_pools do
    Pool
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_while_ok([], fn
      %{address: address} ->
        with {:ok, status} <- query_pool(address) do
          Pool.from_query(address, status)
        end
    end)
  end

  def query_pool(address) do
    Contracts.query_state_smart(address, %{status: %{}})
  end

  def pool_from_id(id) do
    with {:ok, pool} <- query_pool(id) do
      Pool.from_query(id, pool)
    end
  end

  def accounts(address) do
    with {:ok, pools} <- list_pools() do
      Rujira.Enum.reduce_while_ok(pools, [], fn
        pool ->
          case load_account(pool, address) do
            {:ok, %{lp_shares: 0, xlp_shares: 0}} -> :skip
            other -> other
          end
      end)
    end
  end

  def account_from_id(id) do
    with [account, pool] <- String.split(id, "/", parts: 2) do
      with {:ok, pool} <- pool_from_id(pool),
           {:ok, query} <- query_account(pool, account) do
        Account.from_query(pool, account, query)
      end
    end
  end

  def load_account(pool, address) do
    with {:ok, query} <- query_account(pool, address) do
      Account.from_query(pool, address, query)
    end
  end

  def query_account(pool, account) do
    Contracts.query_state_smart(pool.address, %{lp_info: %{liquidity_provider: account}})
  end
end
