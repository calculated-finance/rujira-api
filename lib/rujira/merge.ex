defmodule Rujira.Merge do
  @moduledoc """
  Rujira Merge.
  """

  alias Rujira.Merge.Account
  alias Rujira.Contracts
  alias Rujira.Merge.Pool
  alias Rujira.Merge.Account
  use GenServer
  use Memoize

  @code_ids :rujira
            |> Application.compile_env(__MODULE__)
            |> Keyword.get(:code_ids)

  def start_link(_) do
    Supervisor.start_link([__MODULE__.Listener], strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Fetches all Merge Pools
  """

  @spec list_pools(list(integer())) ::
          {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def list_pools(code_ids \\ @code_ids) when is_list(code_ids) do
    with {:ok, pools} <- Contracts.list(Pool, code_ids) do
      {:ok,
       ["thor.kuji", "thor.rkuji", "thor.fuzn", "thor.nstk", "thor.wink", "thor.lvn"]
       |> Enum.reduce([], fn denom, acc ->
         case Enum.find(pools, fn x -> x.merge_denom == denom end) do
           nil -> acc
           pool -> [pool | acc]
         end
       end)}
    end
  end

  @doc """
  Fetches the Merge Pool contract and its current config from the chain
  """

  @spec get_pool(String.t()) ::
          {:ok, Pool.t()}
          | {:error, :not_found}
          | {:error, GRPC.RPCError.t()}
          | {:error, :parse_error}
  def get_pool(address), do: Contracts.get({Pool, address})

  @spec pool_from_id(String.t()) ::
          {:ok, Pool.t()}
          | {:error, :not_found}
          | {:error, GRPC.RPCError.t()}
          | {:error, :parse_error}
  def pool_from_id(id) do
    with {:ok, pool} <- get_pool(id),
         {:ok, pool} <- load_pool(pool) do
      {:ok, pool}
    end
  end

  @doc """
  Loads the current Status into the Pool
  """

  @spec load_pool(Pool.t()) ::
          {:ok, Pool.t()} | {:error, GRPC.RPCError.t()} | {:error, :parse_error}
  def load_pool(pool) do
    with {:ok, res} <- query_pool(pool.address),
         {:ok, status} <- Rujira.Merge.Pool.Status.from_query(pool, res) do
      {:ok, Pool.set_rate(%{pool | status: status})}
    end
  end

  defmemop query_pool(address) do
    Contracts.query_state_smart(address, %{status: %{}})
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
    with {:ok, {share_pool, account_shares, account_merged}} <-
           query_account(pool.address, account) do
      Account.from_query(pool, %{
        "addr" => account,
        "merged" => account_merged,
        "shares" => account_shares,
        "size" => Account.ownership(share_pool, account_shares)
      })
    else
      {:error, :not_found} ->
        Account.from_query(pool, %{
          "addr" => account,
          "merged" => "0",
          "shares" => "0",
          "size" => "0"
        })
    end
  end

  defmemop query_account(address, account) do
    prefix = "accounts"
    separator = <<0>>
    prefix_len = <<byte_size(prefix)>>

    # SharePool has an overflow in its `ownership` query. Do the raw queries and calculate it here
    with {:ok, share_pool} <- Contracts.query_state_raw(address, "pool"),
         {:ok, [account_shares, account_merged]} <-
           Contracts.query_state_raw(
             address,
             separator <> prefix_len <> prefix <> account
           ) do
      {:ok, {share_pool, account_shares, account_merged}}
    end
  end

  def account_from_id(id) do
    [pool, account] = String.split(id, "/")

    with {:ok, pool} <- get_pool(pool),
         {:ok, account} <- load_account(pool, account) do
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
             _, {:error, err} -> {:error, err}
           end) do
      {:ok, accounts}
    end
  end
end
