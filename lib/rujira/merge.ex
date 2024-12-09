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

  @spec list_pools(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def list_pools(channel, code_ids \\ @code_ids) when is_list(code_ids),
    do: Contract.list(channel, Pool, code_ids)

  @doc """
  Fetches the Merge Pool contract and its current config from the chain
  """

  @spec get_pool(GRPC.Channel.t(), String.t()) :: {:ok, Pool.t()} | {:error, :not_found}
  def get_pool(channel, address), do: Contract.get(channel, {Pool, address})

  @doc """
  Loads the current Status into the Pool
  """

  @spec load_pool(GRPC.Channel.t(), Pool.t()) :: {:ok, Pool.t()} | {:error, GRPC.RPCError.t()}
  def load_pool(channel, pool) do
    with {:ok, res} <- Rujira.Contract.query_state_smart(channel, pool.address, %{status: %{}}),
         {:ok, status} <- Rujira.Merge.Pool.Status.from_query(res) do
      {:ok, %{pool | status: status}}
    else
      err -> err
    end
  end

  @doc """
  Loads an Account Pool by account address
  """
  @spec load_account(GRPC.Channel.t(), Pool.t(), String.t()) ::
          {:ok, Account.t()} | {:error, GRPC.RPCError.t()}
  def load_account(channel, pool, account) do
    with {:ok, res} <-
           Rujira.Contract.query_state_smart(channel, pool.address, %{account: %{addr: account}}),
         {:ok, account} <- Rujira.Merge.Account.from_query(pool, res) do
      {:ok, account}
    end
  end
end
