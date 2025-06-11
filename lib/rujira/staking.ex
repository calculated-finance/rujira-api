defmodule Rujira.Staking do
  @moduledoc """
  Rujira Staking.
  """

  alias Rujira.Deployments
  alias Rujira.Staking.Listener
  alias Rujira.Staking.Pool.Status
  alias Rujira.Staking.Account
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Account
  alias Rujira.Contracts
  use Memoize

  use Supervisor

  def start_link(_) do
    children = [Listener]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def single() do
    with %{address: address} <- Deployments.get_target(Pool, "ruji") do
      address
    end
  end

  def dual(), do: nil

  @doc """
  Fetches all Pools
  """
  @spec list_pools() ::
          {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def list_pools() do
    Pool
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_while_ok([], fn %{module: module, address: address} ->
      Contracts.get({module, address})
    end)
  end

  @doc """
  Fetches the Staking Pool contract and its current config from the chain
  """

  @spec get_pool(String.t() | nil) :: {:ok, Pool.t()} | {:error, :not_found}
  def get_pool(nil), do: {:ok, nil}
  def get_pool(address), do: Contracts.get({Pool, address})

  # def list_pools(code_ids \\ @code_ids) when is_list(code_ids),
  #   do: Contract.list(Pool, code_ids)

  @doc """
  Loads the current Status into the Pool
  """
  @spec load_pool(Pool.t()) :: {:ok, Pool.t()} | {:error, GRPC.RPCError.t()}

  def load_pool(pool) do
    with {:ok, status} <- query_pool(pool.address),
         {:ok, status} <- Status.from_query(pool.address, status) do
      {:ok, %{pool | status: status}}
    end
  end

  defmemop query_pool(contract) do
    Contracts.query_state_smart(contract, %{status: %{}})
  end

  def pool_from_id(id) do
    with {:ok, pool} <- get_pool(id) do
      {:ok, pool}
    end
  end

  def account_from_id(id) do
    [pool, account] = String.split(id, "/")

    with {:ok, pool} <- get_pool(pool),
         {:ok, account} <- load_account(pool, account) do
      {:ok, account}
    end
  end

  def status_from_id(id) do
    with {:ok, status} <- query_pool(id) do
      Status.from_query(id, status)
    end
  end

  def summary_from_id(id) do
    with {:ok, pool} <- get_pool(id) do
      Pool.summary(pool)
    end
  end

  @doc """
  Loads an Account Pool by account address
  """
  @spec load_account(Pool.t() | nil, String.t()) ::
          {:ok, Account.t()} | {:error, GRPC.RPCError.t()}
  def load_account(nil, _), do: {:ok, nil}

  def load_account(pool, account) do
    with {:ok, res} <- query_account(pool.address, account) do
      Account.from_query(pool, res)
    else
      _ -> Account.default(pool, account)
    end
  end

  defmemop query_account(contract, address) do
    Contracts.query_state_smart(contract, %{account: %{addr: address}})
  end
end
