defmodule Rujira.Fin do
  use GenServer
  alias Rujira.Fin.TradingView
  alias Rujira.Fin.Trades.Trade
  alias Rujira.Contract
  alias Rujira.Fin.Candle
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Book
  alias Rujira.Fin.Order
  import Ecto.Query
  alias Rujira.Repo
  require Logger

  def start_link(_) do
    children = [
      __MODULE__.Listener,
      __MODULE__.Indexer
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @moduledoc """
  Rujira's 100% on-chain, central limit order book style decentralized token exchange.
  """

  @pair_code_ids Application.compile_env(:rujira, __MODULE__, pair_code_ids: [58])
                 |> Keyword.get(:pair_code_ids)

  @doc """
  Fetches the Pair contract and its current config from the chain
  """

  @spec get_pair(String.t()) :: {:ok, Pair.t()} | {:error, GRPC.RPCError.t()}
  def get_pair(address) do
    Contract.get({Pair, address})
  end

  @doc """
  Fetches all Pairs
  """
  @spec list_pairs(list(integer())) ::
          {:ok, list(Pair.t())} | {:error, GRPC.RPCError.t()}
  def list_pairs(code_ids \\ @pair_code_ids) when is_list(code_ids),
    do: Contract.list(Pair, code_ids)

  @doc """
  Loads the current Book into the Pair
  """
  @spec load_pair(Pair.t(), integer()) ::
          {:ok, Pair.t()} | {:error, GRPC.RPCError.t()}
  def load_pair(pair, limit \\ 100) do
    with {:ok, res} <-
           Contract.query_state_smart(pair.address, %{book: %{limit: limit}}),
         {:ok, book} <- Book.from_query(pair.address, res) do
      {:ok, %{pair | book: book}}
    else
      err ->
        err
    end
  end

  @doc """
  Fetches all Orders for a pair
  """
  @spec list_orders(Pair.t(), String.t()) ::
          {:ok, list(Order.t())} | {:error, GRPC.RPCError.t()}
  def list_orders(pair, address, offset \\ 0, limit \\ 30) do
    with {:ok, %{"orders" => orders}} <-
           Contract.query_state_smart(pair.address, %{
             orders: %{owner: address, offset: offset, limit: limit}
           }) do
      {:ok, Enum.map(orders, &Order.from_query(pair, &1))}
    else
      err ->
        err
    end
  end

  def list_all_orders(address) do
    with {:ok, pairs} <- list_pairs(),
         {:ok, orders} <-
           Task.async_stream(pairs, &list_orders(&1, address))
           |> Enum.reduce({:ok, []}, fn
             # Flatten orders here
             {:ok, {:ok, orders}}, {:ok, acc} -> {:ok, acc ++ orders}
             {:ok, {:error, error}}, _ -> {:error, error}
             {:error, err}, _ -> {:error, err}
           end) do
      {:ok, orders}
    end
  end

  def list_account_history(_address) do
    {:ok, []}
  end

  def candle_from_id(id) do
    {:ok, get_candle(id)}
  end

  def get_candle(id) do
    Candle
    |> where([c], c.id == ^id)
    |> Repo.one()
  end

  def list_candles(ids) do
    Candle
    |> where([c], c.id in ^ids)
    |> Repo.all()
  end

  def pair_from_id(id) do
    get_pair(id)
  end

  def book_from_id(id) do
    with {:ok, res} <-
           Contract.query_state_smart(id, %{book: %{}}),
         {:ok, book} <- Book.from_query(id, res) do
      {:ok, book}
    end
  end

  def order_from_id(id) do
    Order.from_id(id)
  end

  @spec all_trades(non_neg_integer(), :asc | :desc) :: [Trade.t()]
  def all_trades(limit \\ 100, sort \\ :desc) do
    Trade
    |> sort_trades(sort)
    |> limit(^limit)
    |> Repo.all()
  end

  @spec list_trades(String.t(), non_neg_integer(), :asc | :desc) :: [Trade.t()]
  def list_trades(contract, limit \\ 100, sort \\ :desc) do
    Trade
    |> where(contract: ^contract)
    |> sort_trades(sort)
    |> limit(^limit)
    |> Repo.all()
  end

  def insert_trades(trades) do
    with {_count, items} when is_list(items) <-
           Repo.insert_all(Trade, trades, on_conflict: :nothing, returning: true) do
      update_candles(items)
    end
  end

  def sort_trades(query, dir) do
    order_by(query, [x], [
      {^dir, x.height},
      {^dir, x.tx_idx},
      {^dir, x.idx}
    ])
  end

  def update_candles(trades) do
    now = DateTime.utc_now()

    entries =
      trades
      |> Enum.flat_map(fn v ->
        v.timestamp
        |> TradingView.active()
        |> Enum.map(fn {r, b} ->
          %{
            id: "#{v.contract}/#{r}/#{DateTime.to_iso8601(b)}",
            contract: v.contract,
            resolution: r,
            bin: b,
            high: v.rate,
            low: v.rate,
            open: v.rate,
            close: v.rate,
            volume:
              case v do
                %{side: :base, offer: offer} -> offer
                %{side: :quote, bid: bid} -> bid
              end,
            inserted_at: now,
            updated_at: now
          }
        end)
      end)

    on_conflict =
      from(c in Candle,
        update: [
          set: [
            high: fragment("GREATEST(EXCLUDED.high, ?)", c.high),
            low: fragment("LEAST(EXCLUDED.low, ?)", c.low),
            open: fragment("COALESCE(?, EXCLUDED.open)", c.open),
            close: fragment("EXCLUDED.close"),
            volume: fragment("EXCLUDED.volume + ?", c.volume),
            updated_at: fragment("EXCLUDED.updated_at")
          ]
        ]
      )

    {_count, candles} =
      Repo.insert_all(
        Candle,
        entries,
        on_conflict: on_conflict,
        conflict_target: [:contract, :resolution, :bin],
        returning: true
      )

    for c <- candles do
      Logger.debug("#{__MODULE__} candle #{c.id}")

      id =
        Absinthe.Relay.Node.to_global_id(
          :fin_candle,
          c.id,
          RujiraWeb.Schema
        )

      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end
  end
end
