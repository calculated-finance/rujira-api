defmodule Rujira.Merge do
  @moduledoc """
  Rujira Merge.
  """

  alias Rujira.Merge.Account
  alias Rujira.Contract
  alias Rujira.Merge.Pool
  alias Rujira.Merge.Account

  @code_ids Application.compile_env(:kujira, __MODULE__, code_ids: [31])
            |> Keyword.get(:code_ids)

  @doc """
  Fetches all Merge Pools
  """

  @spec list_pools(list(integer())) ::
          {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def list_pools(code_ids \\ @code_ids) when is_list(code_ids),
    do: Contract.list(Pool, code_ids)

  @doc """
  Fetches the Merge Pool contract and its current config from the chain
  """

  @spec get_pool(String.t()) :: {:ok, Pool.t()} | {:error, :not_found}
  def get_pool(address), do: Contract.get({Pool, address})

  @doc """
  Loads the current Status into the Pool
  """

  @spec load_pool(Pool.t()) :: {:ok, Pool.t()} | {:error, GRPC.RPCError.t()}
  def load_pool(pool) do
    with {:ok, res} <- Rujira.Contract.query_state_smart(pool.address, %{status: %{}}),
         {:ok, status} <- Rujira.Merge.Pool.Status.from_query(res) do
      {:ok, %{pool | status: status}}
    else
      err -> err
    end
  end

  @doc """
  Gets and Loads all pools
  """
  @spec load_pools() :: {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def load_pools() do
    with {:ok, pools} <- Rujira.Merge.list_pools(),
         {:ok, stats} <-
           Task.async_stream(pools, &Rujira.Merge.load_pool/1)
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
    with {:ok, res} <-
           Rujira.Contract.query_state_smart(pool.address, %{account: %{addr: account}}),
         {:ok, account} <- Rujira.Merge.Account.from_query(pool, res) do
      {:ok, account}
    end
  end

  @spec load_accounts(String.t()) :: {:ok, list(Account.t())} | {:error, GRPC.RPCError.t()}
  def load_accounts(account) do
    with {:ok, pools} <- Rujira.Merge.list_pools(),
         {:ok, accounts} <-
           Task.async_stream(pools, &Rujira.Merge.load_account(&1, account))
           |> Enum.reduce({:ok, []}, fn
             {:ok, {:ok, pool}}, {:ok, acc} -> {:ok, [pool | acc]}
             {:ok, {:error, error}}, _ -> {:error, error}
             {:error, err}, _ -> {:error, err}
           end) do
      {:ok, accounts}
    end
  end
end
