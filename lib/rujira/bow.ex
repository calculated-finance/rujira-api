defmodule Rujira.Bow do
  @moduledoc """
  Rujira Bow - AMM pools.
  """

  alias Rujira.Bow.Account
  alias Rujira.Chains.Thor
  alias Rujira.Contracts
  alias Rujira.Bow.Xyk
  # use GenServer

  @code_ids Application.compile_env(:rujira, __MODULE__, code_ids: [110])
            |> Keyword.get(:code_ids)

  # def start_link(_) do
  #   Supervisor.start_link([__MODULE__.Listener], strategy: :one_for_one)
  # end

  # @impl true
  # def init(state) do
  #   {:ok, state}
  # end

  @doc """
  Fetches all Bow Pools
  """

  @spec list_pools(list(integer())) ::
          {:ok, list(Xyk.t())} | {:error, GRPC.RPCError.t()}
  def list_pools(code_ids \\ @code_ids) when is_list(code_ids) do
    with {:ok, contracts} <- Contracts.by_codes(@code_ids) do
      contracts
      |> Task.async_stream(&load_pool/1, timeout: 30_000)
      |> Enum.reduce({:ok, []}, fn
        {:ok, {:ok, x}}, {:ok, xs} ->
          {:ok, [x | xs]}

        _, err ->
          err
      end)
    end
  end

  @doc """
  Fetches the Merge Pool contract and its current config from the chain
  """

  def load_pool(%{address: address}) do
    case Contracts.query_state_smart(address, %{strategy: %{}}) do
      {:ok, %{"xyk" => xyk}} -> Xyk.from_query(address, xyk)
      {:error, err} -> {:error, err}
    end
  end

  def pool_from_id(id) do
    load_pool(id)
  end

  @doc """
  Loads an Account Pool by account address
  """
  @spec load_account(Xyk.t() | nil, String.t()) ::
          {:ok, Account.t()} | {:error, GRPC.RPCError.t()}
  def load_account(nil, _), do: {:ok, nil}

  def load_account(pool, account) do
    with {:ok, %{amount: shares}} <- Thor.balance_of(account, pool.config.share_denom) do
      {:ok,
       %Account{
         id: "#{pool.id}/#{account}",
         account: account,
         pool: pool,
         shares: shares,
         value: share_value(shares, pool)
       }}
    end
  end

  def account_from_id(id) do
    [pool, account] = String.split(id, "/")

    with {:ok, pool} <- load_pool(%{address: pool}) do
      load_account(pool, account)
    end
  end

  def share_value(_, %Xyk{state: %{shares: 0}}), do: []

  def share_value(shares, %Xyk{config: config, state: %{x: x, y: y, shares: supply}}) do
    ratio = Decimal.div(Decimal.new(shares), Decimal.new(supply))

    [
      %{
        amount:
          x |> Decimal.new() |> Decimal.mult(ratio) |> Decimal.round() |> Decimal.to_integer(),
        denom: config.x
      },
      %{
        amount:
          y |> Decimal.new() |> Decimal.mult(ratio) |> Decimal.round() |> Decimal.to_integer(),
        denom: config.y
      }
    ]
  end
end
