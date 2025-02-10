defmodule Rujira.Fin do
  use GenServer

  def start_link(_) do
    children = [
      __MODULE__.Listener,
      __MODULE__.Trades.Indexer
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
  alias Rujira.Contract
  alias Rujira.Fin.Candle
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Book
  alias Rujira.Fin.Order

  @pair_code_ids Application.compile_env(:rujira, __MODULE__, pair_code_ids: [39])
                 |> Keyword.get(:pair_code_ids)

  @doc """
  Fetches the Pair contract and its current config from the chain
  """

  @spec get_pair(String.t()) :: {:ok, Pair.t()} | {:error, GRPC.RPCError.t()}
  def get_pair(address) do
    with {:ok, pair} <- Contract.get({Pair, address}) do
      load_status(pair)
    end
  end

  @doc """
  Fetches all Pairs
  """

  @spec list_pairs(list(integer())) ::
          {:ok, list(Pair.t())} | {:error, GRPC.RPCError.t()}
  def list_pairs(code_ids \\ @pair_code_ids) when is_list(code_ids),
    do: Contract.list(Pair, code_ids)

  @doc """
  Load the Status of a Pair
  """

  @spec load_status(Pair.t()) ::
          {:ok, Pair.t()} | {:error, GRPC.RPCError.t()}
  def load_status(pair) do
    with {:ok, res} <- Contract.query_state_smart(pair.address, %{status: %{}}),
         {:ok, status} <- Pair.Status.from_query(res) do
      {:ok, %{pair | status: status}}
    end
  end

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

  def account_history(_address) do
    {:ok, []}
  end

  def set_pair_history(pair) do
    history = [{}]
    {:ok, %{pair | history: history}}
  end

  def set_summary(pair) do
    summary = [{}]
    {:ok, %{pair | summary: summary}}
  end

  def candles(address, _, _, resolution) do
    bin = DateTime.utc_now()

    candles = [
      %Candle{
        id: Candle.to_id(address, resolution, bin),
        high: 300_000_000_000,
        low: 100_000_000_000,
        open: 150_000_000_000,
        close: 250_000_000_000,
        volume: 300_000_000_000,
        bin: bin
      }
    ]

    {:ok, candles}
  end

  def pair_from_id(id) do
    get_pair(id)
  end

  def book_from_id(id) do
    with {:ok, res} <-
           Contract.query_state_smart(id, %{book: %{}}),
         {:ok, book} <- Book.from_query(id, res) do
      {:ok, book}
    else
      err ->
        err
    end
  end

  def order_from_id(id) do
    Order.from_id(id)
  end
end
