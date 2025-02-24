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

  @pair_code_ids Application.compile_env(:rujira, __MODULE__, pair_code_ids: [56])
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
    [contract, resolution, bin] = String.split(id, "/")

    Candle
    |> where(
      [c],
      c.contract == ^contract and c.resolution == ^resolution and c.bin == ^bin
    )
    |> Repo.one()
    |> set_candle_id()
  end

  def list_candles(ids) do
    Candle
    |> where([c], fragment("concat(?, '/', ?, '/', ?)", c.contract, c.resolution, c.bin) in ^ids)
    |> Repo.all()
    |> Enum.map(&set_candle_id/1)
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
    active = TradingView.active(now)

    entries =
      trades
      |> Enum.group_by(& &1.contract)
      |> Enum.flat_map(fn {k, v} ->
        rates = Enum.map(v, & &1.rate)
        high = Enum.max(rates, &Decimal.gte?/2)
        low = Enum.min(rates, &Decimal.gte?/2)
        open = Enum.at(rates, 0)
        close = Enum.at(rates, -1)

        volume =
          Enum.reduce(trades, 0, fn
            %{side: :base, offer: offer}, a -> a + offer
            %{side: :quote, bid: bid}, a -> a + bid
          end)

        Enum.map(active, fn {r, b} ->
          %{
            contract: k,
            resolution: r,
            bin: b,
            high: high,
            low: low,
            open: open,
            close: close,
            volume: volume,
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
      c = set_candle_id(c)
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

  def set_candle_id(nil), do: nil

  def set_candle_id(%Candle{contract: contract, resolution: resolution, bin: bin} = c) do
    %{c | id: "#{contract}/#{resolution}/#{DateTime.to_iso8601(bin)}"}
  end
end
