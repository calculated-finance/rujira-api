defmodule Rujira.Fin do
  @moduledoc """
  Rujira's 100% on-chain, central limit order book style decentralized token exchange.
  """
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Book
  alias Rujira.Fin.Order

  @pair_code_ids Application.compile_env(:rujira, __MODULE__, pair_code_ids: [])
                 |> Keyword.get(:pair_code_ids)

  # TODO - REMOVE COMMENT AND DELETE MOCK FUNCTION ONCE THE CONTRACTS ARE READY

  @doc """
  Fetches the Pair contract and its current config from the chain
  """

  # @spec get_pair(String.t()) :: {:ok, Pair.t()} | {:error, :not_found}
  # def get_pair(address), do: Contract.get({Pair, address})
  def get_pair(_address) do
    pair = %Pair{
      address: "sthor1qm7vtdca95aj7nvtrarqm3uah33nhffpnhhg3j",
      token_base: "gaia-kuji",
      token_quote: "gaia-fuzn",
      price_precision: 12,
      decimal_delta: 2,
      is_bootstrapping: false,
      fee_taker: trunc(0.0015 * 1_000_000_000_000),
      fee_maker: trunc(0.00075 * 1_000_000_000_000),
      book: :not_loaded,
      id: 1
    }

    with {:ok, pair} <- set_pair_history(pair),
         {:ok, pair} <- set_summary(pair),
         {:ok, _pair} <- set_candles(pair) do
    end

    {:ok, pair}
  end

  @doc """
  Fetches all Pairs
  """

  # @spec list_pairs(list(integer())) ::
  #         {:ok, list(Pair.t())} | {:error, GRPC.RPCError.t()}
  # def list_pairs(code_ids \\ @pair_code_ids) when is_list(code_ids),
  #   do: Contract.list(Pair, code_ids)

  def list_pairs(code_ids \\ @pair_code_ids) when is_list(code_ids) do
    {:ok,
     [
       %Pair{
         address: "sthor1qm7vtdca95aj7nvtrarqm3uah33nhffpnhhg3j",
         token_base: "gaia-kuji",
         token_quote: "gaia-fuzn",
         price_precision: 12,
         decimal_delta: 2,
         is_bootstrapping: false,
         fee_taker: trunc(0.0015 * 1_000_000_000_000),
         fee_maker: trunc(0.00075 * 1_000_000_000_000),
         book: :not_loaded,
         id: 1
       },
       %Pair{
         address: "sthor1qm7vtdca95aj7nvtrarqm3uah33nhffpnhhg3z",
         token_base: "gaia-kuji",
         token_quote: "rune",
         price_precision: 12,
         decimal_delta: 2,
         is_bootstrapping: false,
         fee_taker: trunc(0.0015 * 1_000_000_000_000),
         fee_maker: trunc(0.00075 * 1_000_000_000_000),
         book: :not_loaded,
         id: 2
       },
       %Pair{
         address: "sthor1qm7vtdca95aj7nvtrarqm3uah33nhffpnhhg32",
         token_base: "gaia-kuji",
         token_quote: "gaia-atom",
         price_precision: 12,
         decimal_delta: 2,
         is_bootstrapping: false,
         fee_taker: trunc(0.0015 * 1_000_000_000_000),
         fee_maker: trunc(0.00075 * 1_000_000_000_000),
         book: :not_loaded,
         id: 3
       }
     ]}
  end

  @doc """
  Loads the current Book into the Pair
  """

  # @spec load_pair(Pair.t(), integer()) ::
  #         {:ok, Pair.t()} | {:error, GRPC.RPCError.t()}
  # def load_pair(pair, limit \\ 100) do
  #   with {:ok, res} <-
  #          Contract.query_state_smart(pair.address, %{book: %{limit: limit}}),
  #        {:ok, book} <- Book.from_query(res) do
  #     {:ok, %{pair | book: book}}
  #   else
  #     err ->
  #       err
  #   end
  # end

  def load_pair(pair, _limit \\ 100) do
    book = %Book{
      bids: [
        %Book.Price{price: 100, total: 10, side: :bid},
        %Book.Price{price: 95, total: 20, side: :bid}
      ],
      asks: [
        %Book.Price{price: 105, total: 15, side: :ask},
        %Book.Price{price: 110, total: 25, side: :ask}
      ]
    }

    {:ok, %{pair | book: book}}
  end

  @doc """
  Fetches all Orders for a pair
  """

  # @spec list_orders(Pair.t(), String.t()) ::
  #         {:ok, list(Order.t())} | {:error, GRPC.RPCError.t()}
  # def list_orders(pair, address) do
  #   with {:ok, %{"orders" => orders}} <-
  #          Contract.query_state_smart(pair.address, %{
  #            orders_by_user: %{address: address}
  #          }) do
  #     {:ok, Enum.map(orders, &Order.from_query(pair, &1))}
  #   else
  #     err ->
  #       err
  #   end
  # end

  def list_orders(pair, address) do
    {:ok,
     [
       %Order{
         pair: pair.address,
         id: "order1",
         owner: address,
         price: 105,
         offer_token: "gaia-kuji",
         original_offer_amount: 1000,
         remaining_offer_amount: 500,
         filled_amount: 500,
         created_at: ~U[2024-12-20T10:00:00Z]
       },
       %Order{
         pair: pair.address,
         id: "order2",
         owner: address,
         price: 95,
         offer_token: "gaia-fuzn",
         original_offer_amount: 2000,
         remaining_offer_amount: 1500,
         filled_amount: 500,
         created_at: ~U[2024-12-19T15:30:00Z]
       }
     ]}
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

  def account_history(address) do
    {:ok, []}
  end

  def set_pair_history(pair) do
    history = [{}]
    {:ok, %{pair | history: history}}
  end

  def set_candles(pair) do
    candles = [{}]
    {:ok, %{pair | candles: candles}}
  end

  def set_summary(pair) do
    summary = [{}]
    {:ok, %{pair | summary: summary}}
  end
end
