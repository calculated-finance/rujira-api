defmodule Rujira.Staking do
  @moduledoc """
  Rujira Staking.
  """

  alias Rujira.Staking.Account
  alias Rujira.Contract
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Account

  @code_ids Application.compile_env(:rujira, __MODULE__, code_ids: [1])
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
  def list_pools(code_ids \\ @code_ids) when is_list(code_ids) do
    {:ok,
     [
       %Pool{
         address: "sthor1",
         bond_denom: "THOR-RUJI",
         revenue_denom: "eth-usdc-0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
         revenue_converter: {"contract1", <<1, 2, 3>>, 1000},
         status: :not_loaded,
         id: 1
       },
       %Pool{
         address: "sthor2",
         bond_denom: "THOR-RUJI",
         revenue_denom: "eth-usdc-0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
         revenue_converter: {"contract2", <<4, 5, 6>>, 2000},
         status: :not_loaded,
         id: 2
       }
     ]}
  end

  # def list_pools(code_ids \\ @code_ids) when is_list(code_ids),
  #   do: Contract.list(Pool, code_ids)

  @doc """
  Loads the current Status into the Pool
  """
  @spec load_pool(Pool.t()) :: {:ok, Pool.t()} | {:error, GRPC.RPCError.t()}

  def load_pool(pool) do
    {:ok,
     %{
       pool
       | status: %Pool.Status{
           account_bond: 1000,
           account_revenue: 2000,
           liquid_bond_shares: 3000,
           liquid_bond_size: 4000,
           pending_revenue: 5000
         }
     }}
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
