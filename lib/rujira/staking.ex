defmodule Rujira.Staking do
  @moduledoc """
  Rujira Staking.
  """

  alias Rujira.Staking.Listener
  alias Rujira.Staking.Pool.Status
  alias Rujira.Staking.Account
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Account
  alias Rujira.Contracts

  use Supervisor

  @single :rujira
          |> Application.compile_env(__MODULE__,
            single: "sthor1k0grs37wafwjdawc27fsqdrl2y3ghuad2dqdrwmnj56tz084xrmsmdydfs"
          )
          |> Keyword.get(:single)

  @dual :rujira
        |> Application.compile_env(__MODULE__, dual: nil)
        |> Keyword.get(:dual)

  def start_link(_) do
    children = [Listener]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def single(), do: @single
  def dual(), do: @dual

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
    with {:ok, status} <- Contracts.query_state_smart(pool.address, %{status: %{}}),
         {:ok, status} <- Status.from_query(pool.address, status) do
      {:ok, %{pool | status: status}}
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
    with {:ok, status} <- Contracts.query_state_smart(id, %{status: %{}}) do
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
    with {:ok, res} <- Contracts.query_state_smart(pool.address, %{account: %{addr: account}}) do
      Account.from_query(pool, res)
    end
  end
end
