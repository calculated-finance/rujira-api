defmodule Rujira.Staking do
  @moduledoc """
  Rujira Staking.
  """

  alias Rujira.Balances
  alias Rujira.Chains.Thor
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Staking.Account
  alias Rujira.Staking.Listener
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Pool.Status

  use Memoize

  use Supervisor

  def start_link(_) do
    children = [Listener]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    list_pools()
    {:ok, state}
  end

  def single do
    with %{address: address} <- Deployments.get_target(Pool, "ruji") do
      address
    end
  end

  def dual, do: nil

  @doc """
  Fetches all Pools
  """
  @spec list_pools :: {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def list_pools do
    Pool
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_while_ok(
      [],
      fn
        %{status: :preview} = target ->
          Pool.from_target(target)

        %{module: module, address: address} ->
          Contracts.get({module, address})
      end
    )
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
    get_pool(id)
  end

  def account_from_id(id) do
    with [account, denom] <- String.split(id, "/", parts: 2) do
      with {:ok, pool} <- pool_from_bond_denom(denom) do
        load_account(pool, account)
      end
    end
  end

  def pool_from_bond_denom(bond_denom) do
    case bond_denom_map() do
      %{} = map ->
        case Map.get(map, bond_denom) do
          nil -> {:error, :not_found}
          pool -> {:ok, pool}
        end

      error ->
        error
    end
  end

  def bond_denom_map do
    case list_pools() do
      {:ok, pools} ->
        pools
        |> Enum.map(&{&1.bond_denom, &1})
        |> Enum.into(%{})

      error ->
        error
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
    case query_account(pool.address, account) do
      {:ok, res} ->
        Account.from_query(pool, res)

      _ ->
        Account.default(pool, account)
    end
  end

  defmemop query_account(contract, address) do
    Contracts.query_state_smart(contract, %{account: %{addr: address}})
  end

  @doc """
  Fetches the balances of the revenue converter contracts that feed the staking contracts,
  and converts them to the allocation due based on the weight of the target address.
  """
  def converter_balances do
    Rujira.Revenue.Converter
    |> Deployments.list_targets()
    |> Enum.filter(fn %{config: %{"target_addresses" => targets}} ->
      Enum.any?(targets, &(&1["address"] == single()))
    end)
    |> Enum.reduce([], &collect_converter_balance/2)
  end

  defp collect_converter_balance(
         %{address: address, config: %{"target_addresses" => target_addresses}},
         agg
       ) do
    weight =
      Enum.find(target_addresses, &(&1["address"] == single()))["weight"] /
        Enum.reduce(target_addresses, 0, fn x, acc -> acc + x["weight"] end)

    case Thor.balances(address, nil) do
      {:ok, balance} ->
        balance
        |> Enum.map(&%{&1 | amount: round(&1.amount * weight)})
        |> Enum.concat(agg)

      _ ->
        agg
    end
    |> Balances.flatten()
  end
end
