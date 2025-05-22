defmodule Rujira.Fin do
  use GenServer
  alias Rujira.Deployments
  alias Rujira.Resolution
  alias Rujira.Fin.Trade
  alias Rujira.Contracts
  alias Rujira.Fin.Candle
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Book
  alias Rujira.Fin.Order
  alias Rujira.Fin.Summary
  import Ecto.Query
  alias Rujira.Repo
  require Logger
  use Memoize

  def start_link(_) do
    children =
      Resolution.resolutions()
      |> Enum.map(&Supervisor.child_spec({Candle, &1}, id: &1))
      |> Enum.concat([
        __MODULE__.Listener,
        __MODULE__.Indexer
      ])

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @moduledoc """
  Rujira's 100% on-chain, central limit order book style decentralized token exchange.
  """

  @doc """
  Fetches the Pair contract and its current config from the chain
  """

  @spec get_pair(String.t()) :: {:ok, Pair.t()} | {:error, GRPC.RPCError.t()}
  def get_pair(address) do
    Contracts.get({Pair, address})
  end

  @doc """
  Fetches all Pairs
  """
  @spec list_pairs() ::
          {:ok, list(Pair.t())} | {:error, GRPC.RPCError.t()}
  def list_pairs() do
    Pair
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_while_ok([], fn %{module: module, address: address} ->
      Contracts.get({module, address})
    end)
  end

  @doc """
  Loads the current Book into the Pair
  """
  @spec load_pair(Pair.t(), integer()) ::
          {:ok, Pair.t()} | {:error, GRPC.RPCError.t()}
  def load_pair(pair, limit \\ 100) do
    with {:ok, res} <- query_book(pair.address, limit),
         {:ok, book} <- Book.from_query(pair.address, res) do
      {:ok, %{pair | book: book}}
    else
      err ->
        err
    end
  end

  defmemo query_book(contract, limit \\ 100) do
    Contracts.query_state_smart(contract, %{book: %{limit: limit}})
  end

  @doc """
  Fetches all Orders for a pair
  """
  @spec list_orders(Pair.t(), String.t()) ::
          {:ok, list(Order.t())} | {:error, GRPC.RPCError.t()}
  def list_orders(pair, address, offset \\ 0, limit \\ 30) do
    with {:ok, %{"orders" => orders}} <- query_orders(pair.address, address, offset, limit) do
      {:ok, Enum.map(orders, &Order.from_query(pair, &1))}
    else
      err ->
        err
    end
  end

  defmemo query_orders(contract, address, offset \\ 0, limit \\ 30) do
    Contracts.query_state_smart(contract, %{
      orders: %{owner: address, offset: offset, limit: limit}
    })
  end

  def list_all_orders(address) do
    with {:ok, pairs} <- list_pairs(),
         {:ok, orders} <-
           Task.async_stream(pairs, &list_orders(&1, address), timeout: 15_000)
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

  @spec candle_from_id(any()) :: {:error, :not_found} | {:ok, Candle.t()}
  def candle_from_id(id) do
    case get_candle(id) do
      nil -> {:error, :not_found}
      candle -> {:ok, candle}
    end
  end

  @spec get_candle(String.t()) :: Candle.t() | nil
  def get_candle(id) do
    Candle
    |> where(id: ^id)
    |> Repo.one()
  end

  @spec list_candles(list(String.t())) :: list(Candle.t())
  def list_candles(ids) do
    Candle
    |> where([c], c.id in ^ids)
    |> Repo.all()
  end

  def range_candles(contract, from, to, resolution) do
    Candle
    |> where(
      contract: ^contract,
      resolution: ^resolution
    )
    |> where([c], c.bin >= ^from)
    |> where([c], c.bin <= ^to)
    |> order_by(asc: :bin)
    |> Repo.all()
  end

  def pair_from_id(id) do
    get_pair(id)
  end

  def book_from_id(id) do
    with {:ok, res} <- query_book(id, 100),
         {:ok, book} <- Book.from_query(id, res) do
      {:ok, book}
    end
  end

  def order_from_id(id) do
    with [pair_address, side, price, owner] <- String.split(id, "/"),
         {:ok, pair} <- get_pair(pair_address) do
      load_order(pair, side, price, owner)
    else
      {:error, err} -> {:error, err}
      _ -> {:error, :invalid_id}
    end
  end

  def load_order(%{address: address} = pair, side, price, owner) do
    with {:ok, order} <- query_order(address, owner, side, price) do
      {:ok, Order.from_query(pair, order)}
    else
      {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}} ->
        {:ok, Order.new(address, side, price, owner)}

      err ->
        err
    end
  end

  defmemop query_order(address, owner, side, price) do
    Rujira.Contracts.query_state_smart(
      address,
      %{order: [owner, side, Order.decode_price(price)]}
    )
  end

  def summary_from_id(id) do
    {:ok, get_summary(id)}
  end

  def get_summary(contract) do
    Summary.query()
    |> where([c], c.id == ^contract)
    |> Repo.one()
  end

  def get_summaries() do
    Summary.query()
    |> Repo.all()
  end

  def trade_from_id(id) do
    {:ok, get_trade(id)}
  end

  def get_trade(id) do
    Trade.query()
    |> where([c], c.id == ^id)
    |> Repo.one()
  end

  @spec all_trades(non_neg_integer(), :asc | :desc) :: [Trade.t()]
  def all_trades(limit \\ 100, sort \\ :desc) do
    Trade.query()
    |> sort_trades(sort)
    |> limit(^limit)
    |> Repo.all()
  end

  @spec list_trades_query(String.t(), non_neg_integer(), :asc | :desc) :: Ecto.Query.t()
  def list_trades_query(contract, limit \\ 100, sort \\ :desc) do
    Trade.query()
    |> where(contract: ^contract)
    |> sort_trades(sort)
    |> limit(^limit)
  end

  @spec list_trades(String.t(), non_neg_integer(), :asc | :desc) :: [Trade.t()]
  def list_trades(contract, limit \\ 100, sort \\ :desc) do
    contract
    |> list_trades_query(limit, sort)
    |> Repo.all()
  end

  def insert_trades(trades) do
    with {count, items} when is_list(items) <-
           Repo.insert_all(Trade, trades, on_conflict: :nothing, returning: true) do
      broadcast_trades({count, items})
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

  def insert_candles(time, resolution) do
    now = DateTime.utc_now()

    new =
      from(c in Candle,
        where: c.resolution == ^resolution,
        distinct: c.contract,
        order_by: [desc: c.bin]
      )
      |> Repo.all()
      |> Enum.map(
        &%{
          id: Candle.id(&1.contract, &1.resolution, time),
          contract: &1.contract,
          resolution: &1.resolution,
          volume: 0,
          high: &1.close,
          low: &1.close,
          open: &1.close,
          close: &1.close,
          bin: time,
          inserted_at: now,
          updated_at: now
        }
      )

    Repo.insert_all(Candle, new,
      # Conflict will be hit if race condition has triggered insert before this is reached
      on_conflict: :nothing,
      returning: true
    )
    |> broadcast_candles()
  end

  def update_candles(trades) do
    for t <- trades do
      entries =
        t.timestamp
        |> Resolution.active()
        |> Enum.map(&to_candle(t, &1))

      Candle
      |> Repo.insert_all(
        entries,
        on_conflict: candle_conflict(),
        conflict_target: [:contract, :resolution, :bin],
        returning: true
      )
      |> broadcast_candles()
    end
  end

  defp to_candle(trade, {r, b}) do
    now = DateTime.utc_now()

    %{
      id: Candle.id(trade.contract, r, b),
      contract: trade.contract,
      resolution: r,
      bin: b,
      high: trade.rate,
      low: trade.rate,
      open: trade.rate,
      close: trade.rate,
      volume:
        case trade do
          %{side: :base, offer: offer} -> offer
          %{side: :quote, bid: bid} -> bid
        end,
      inserted_at: now,
      updated_at: now
    }
  end

  defp candle_conflict() do
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
  end

  defp broadcast_trades({_count, trades}) do
    for t <- trades do
      Logger.debug("#{__MODULE__} broadcast trade #{t.id}")

      id = Absinthe.Relay.Node.to_global_id(:fin_trade, t.id, RujiraWeb.Schema)
      prefix = Absinthe.Relay.Node.to_global_id(:fin_trade, t.contract, RujiraWeb.Schema)
      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, edge: prefix)

      id =
        Absinthe.Relay.Node.to_global_id(:fin_pair, t.contract, RujiraWeb.Schema)

      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id)
    end
  end

  defp broadcast_candles({_count, candles}) do
    for c <- candles do
      Logger.debug("#{__MODULE__} broadcast candle #{c.id}")

      id = Absinthe.Relay.Node.to_global_id(:fin_candle, c.id, RujiraWeb.Schema)

      prefix =
        Absinthe.Relay.Node.to_global_id(
          :fin_candle,
          "#{c.contract}/#{c.resolution}",
          RujiraWeb.Schema
        )

      Absinthe.Subscription.publish(RujiraWeb.Endpoint, %{id: id}, node: id, edge: prefix)
    end
  end

  def book_price(id) do
    with {:ok, book} <- book_from_id(id) do
      {:ok, %{price: book.center, change: 0}}
    end
  end
end
