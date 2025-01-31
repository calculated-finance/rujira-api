defmodule Rujira.Fin do
  @moduledoc """
  Rujira's 100% on-chain, central limit order book style decentralized token exchange.
  """
  alias Rujira.Contract
  alias Rujira.Fin.Candle
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Book
  alias Rujira.Fin.Order

  @pair_code_ids Application.compile_env(:rujira, __MODULE__, pair_code_ids: [37])
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
         {:ok, book} <- Book.from_query(res) do
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

  def candles(_address, _from, _to, _resolution) do
    candles = [
      %Candle{
        high: "1",
        low: "2",
        volume: "3",
        time: "4"
      }
    ]

    {:ok, candles}
  end
end
