defmodule Rujira.Staking do
  @moduledoc """
  Rujira Staking.
  """

  alias Rujira.Staking.Pool.Status
  alias Rujira.Staking.Account
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Account
  alias Rujira.Contract

  @code_ids Application.compile_env(:rujira, __MODULE__, code_ids: [100])
            |> Keyword.get(:code_ids)

  @doc """
  Fetches the Staking Pool contract and its current config from the chain
  """

  @spec get_pool(String.t()) :: {:ok, Pool.t()} | {:error, :not_found}
  def get_pool(address) do
    with {:ok, pool} <- list_pools(),
         %Pool{} = pool <- Enum.find(pool, &(&1.address == address)) do
      {:ok, pool}
    else
      nil -> {:error, :not_found}
    end
  end

  # def get_pool(address), do: Contract.get({Pool, address})

  @doc """
  Fetches all Staking Pools
  """

  @spec list_pools(list(integer())) ::
          {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def list_pools(code_ids \\ @code_ids) when is_list(code_ids), do: Contract.list(Pool, code_ids)

  # def list_pools(code_ids \\ @code_ids) when is_list(code_ids),
  #   do: Contract.list(Pool, code_ids)

  @doc """
  Loads the current Status into the Pool
  """
  @spec load_pool(Pool.t()) :: {:ok, Pool.t()} | {:error, GRPC.RPCError.t()}

  def load_pool(pool) do
    with {:ok, status} <- Contract.query_state_smart(pool.address, %{status: %{}}),
         {:ok, status} <- Status.from_query(status) do
      {:ok, %{pool | status: status}}
    end
  end

  # def load_pool(pool) do
  #   with {:ok, res} <- Rujira.Contract.query_state_smart(pool.address, %{status: %{}}),
  #        {:ok, status} <- Rujira.Staking.Pool.Status.from_query(res) do
  #     {:ok, %{pool | status: status}}
  #   else
  #     err -> err
  #   end
  # end

  @doc """
  Gets and Loads all pools
  """
  @spec load_pools() :: {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def load_pools() do
    with {:ok, pools} <- Rujira.Staking.list_pools(),
         {:ok, stats} <-
           Task.async_stream(pools, &Rujira.Staking.load_pool/1)
           |> Enum.reduce({:ok, []}, fn
             {:ok, {:ok, pool}}, {:ok, acc} -> {:ok, [pool | acc]}
             {:ok, {:error, error}}, _ -> {:error, error}
             {:error, err}, _ -> {:error, err}
           end) do
      {:ok, stats}
    end
  end

  @doc """
  Loads an Account Pool by account address
  """
  @spec load_account(Pool.t(), String.t()) ::
          {:ok, Account.t()} | {:error, GRPC.RPCError.t()}
  def load_account(pool, account) do
    {:ok,
     %Account{
       pool: pool,
       account: account,
       bonded: 10000,
       pending_revenue: 20000
     }}
  end

  # def load_account(pool, account) do
  #   with {:ok, res} <-
  #          Rujira.Contract.query_state_smart(pool.address, %{account: %{addr: account}}),
  #        {:ok, account} <- Rujira.Staking.Account.from_query(pool, res) do
  #     {:ok, account}
  #   end
  # end

  @spec load_accounts(String.t()) :: {:ok, list(Account.t())} | {:error, GRPC.RPCError.t()}
  def load_accounts(account) do
    with {:ok, pools} <- Rujira.Staking.list_pools(),
         {:ok, accounts} <-
           Task.async_stream(pools, &Rujira.Staking.load_account(&1, account))
           |> Enum.reduce({:ok, []}, fn
             {:ok, {:ok, pool}}, {:ok, acc} -> {:ok, [pool | acc]}
             {:ok, {:error, error}}, _ -> {:error, error}
             {:error, err}, _ -> {:error, err}
           end) do
      {:ok, accounts}
    end
  end

  def get_summary(_address, _resolution) do
    # TODO indexing revenue earned and calculate apr to retreive these info
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
       revenue_earned: 10_000_000
     }}
  end
end
