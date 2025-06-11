defmodule Rujira.Bow do
  @moduledoc """
  Rujira Bow - AMM pools.
  """

  alias Rujira.Deployments
  alias Rujira.Bow.Account
  alias Rujira.Chains.Thor
  alias Rujira.Contracts
  alias Rujira.Bow.Xyk
  alias Rujira.Fin.Book
  import Ecto.Query
  use Memoize
  use GenServer

  def start_link(_) do
    Supervisor.start_link([__MODULE__.Listener], strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Fetches all Bow Pools
  """

  @spec list_pools() ::
          {:ok, list(Xyk.t())} | {:error, GRPC.RPCError.t()}
  def list_pools() do
    __MODULE__
    |> Deployments.list_targets()
    |> Task.async_stream(&load_pool/1, timeout: 30_000)
    |> Enum.reduce({:ok, []}, fn
      {:ok, {:ok, x}}, {:ok, xs} ->
        {:ok, [x | xs]}

      _, err ->
        err
    end)
  end

  @doc """
  Fetches the Merge Pool contract and its current config from the chain
  """

  def load_pool(%{address: address}) do
    case query_pool(address) do
      {:ok, %{"xyk" => xyk}} -> Xyk.from_query(address, xyk)
      {:error, err} -> {:error, err}
    end
  end

  defmemop query_pool(address) do
    Contracts.query_state_smart(address, %{strategy: %{}})
  end

  def pool_from_id(id) do
    load_pool(%{address: id})
  end

  @doc """
  Loads an Account Pool by account address
  """
  @spec load_account(Xyk.t() | nil, String.t()) ::
          {:ok, Account.t()} | {:error, GRPC.RPCError.t()}
  def load_account(nil, _), do: {:ok, nil}

  def load_account(pool, account) do
    with {:ok, %{amount: shares}} <-
           Thor.balance_of(account, pool.config.share_denom),
         {shares, ""} <- Integer.parse(shares) do
      {:ok,
       %Account{
         id: "#{account}/#{pool.config.share_denom}",
         account: account,
         pool: pool,
         shares: shares,
         value: share_value(shares, pool)
       }}
    end
  end

  def account_from_id(id) do
    with [account, denom] <- String.split(id, "/", parts: 2) do
      with {:ok, pool} <- pool_from_share_denom(denom),
           {:ok, account} <- load_account(pool, account) do
        {:ok, account}
      end
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

  # We don't have any kind of `swap` event on the bow pool, so we need to figure out which
  # fin pair this pool is a market maker for, and find the `mm:` prefixed trades
  @spec list_trades_query(String.t(), non_neg_integer(), :asc | :desc) ::
          {:ok, Ecto.Query.t()} | {:error, any()}
  def list_trades_query(contract, limit \\ 100, sort \\ :desc) do
    with {:ok, %{address: address}} <- fin_pair(contract) do
      {:ok,
       Rujira.Fin.Trade
       |> where(contract: ^address)
       |> where([t], like(t.price, "mm:%"))
       |> Rujira.Fin.Trade.query()
       |> select_merge([t], %{
         type: fragment("CASE WHEN ? = 'base' THEN 'sell' ELSE 'buy' END", t.side)
       })
       |> Rujira.Fin.sort_trades(sort)
       |> limit(^limit)}
    end
  end

  defmemo fin_pair(contract) do
    with {:ok, pairs} <- Rujira.Fin.list_pairs(),
         %Rujira.Fin.Pair{} = pair <-
           Enum.find(pairs, fn %{market_maker: mm} -> mm == contract end) do
      {:ok, pair}
    else
      _ -> {:error, :not_found}
    end
  end

  def load_quotes(address), do: query_quotes(address)

  defmemop query_quotes(address) do
    with {:ok, %Xyk{config: config, state: state}} <- load_pool(%{address: address}) do
      {:ok,
       %Book{
         id: address,
         #  Side is inverted as it's what the orderbook needs to fulfil market trades
         asks: Xyk.do_quotes(config, state, :bid),
         bids: Xyk.do_quotes(config, state, :ask)
       }
       |> Book.populate()}
    end
  end

  def share_denom_map() do
    case list_pools() do
      {:ok, pools} ->
        pools
        |> Enum.map(&{&1.config.share_denom, &1})
        |> Enum.into(%{})

      error ->
        error
    end
  end

  def pool_from_share_denom(share_denom) do
    case share_denom_map() do
      %{} = map ->
        case Map.get(map, share_denom) do
          nil -> {:error, :not_found}
          pool -> {:ok, pool}
        end

      error ->
        error
    end
  end

  def init_msg(%{"strategy" => %{"xyk" => xyk}}), do: Xyk.init_msg(xyk)
  def migrate_msg(from, to, %{"strategy" => %{"xyk" => xyk}}), do: Xyk.migrate_msg(from, to, xyk)
  def init_label(id, %{"strategy" => %{"xyk" => xyk}}), do: Xyk.init_label(id, xyk)
end
