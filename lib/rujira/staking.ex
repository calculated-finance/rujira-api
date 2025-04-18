defmodule Rujira.Staking do
  @moduledoc """
  Rujira Staking.
  """

  alias Rujira.Bank.Transfer
  alias Rujira.Staking.Pool.Status
  alias Rujira.Staking.Account
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Account
  alias Rujira.Contract
  import Ecto.Query
  use Memoize

  @single :rujira
          |> Application.compile_env(__MODULE__,
            single: "sthor1k0grs37wafwjdawc27fsqdrl2y3ghuad2dqdrwmnj56tz084xrmsmdydfs"
          )
          |> Keyword.get(:single)

  @dual :rujira
        |> Application.compile_env(__MODULE__, dual: nil)
        |> Keyword.get(:dual)

  def single(), do: @single
  def dual(), do: @dual

  @doc """
  Fetches the Staking Pool contract and its current config from the chain
  """

  @spec get_pool(String.t() | nil) :: {:ok, Pool.t()} | {:error, :not_found}
  def get_pool(nil), do: {:ok, nil}
  def get_pool(address), do: Contract.get({Pool, address})

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

  @doc """
  Loads an Account Pool by account address
  """
  @spec load_account(Pool.t() | nil, String.t()) ::
          {:ok, Account.t()} | {:error, GRPC.RPCError.t()}
  def load_account(nil, _), do: {:ok, nil}

  def load_account(pool, account) do
    with {:ok, res} <- Contract.query_state_smart(pool.address, %{account: %{addr: account}}) do
      Account.from_query(pool, res)
    end
  end

  defmemo get_revenue(%Pool{address: address, revenue_denom: denom}, days),
    expires_in: 60 * 60 * 1000 do
    Rujira.Repo.one(
      from(t in Transfer,
        select: fragment("SUM(?)::bigint", t.amount),
        where:
          t.denom == ^denom and t.recipient == ^address and
            t.timestamp > ^DateTime.add(DateTime.utc_now(), -days, :day)
      )
    ) || 0
  end
end
