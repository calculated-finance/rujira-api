defmodule Rujira.Fin.Book do
  @moduledoc """
  Parses and represents a FIN.Book from blockchain data.
  """

  defmodule Price do
    @moduledoc """
    Represents a price level in the order book with associated order details.
    """
    defstruct [:price, :total, :side, :value, :virtual_total, :virtual_value]

    @type side :: :bid | :ask
    @type t :: %__MODULE__{
            price: Decimal.t(),
            total: non_neg_integer(),
            side: side,
            value: non_neg_integer(),
            virtual_total: non_neg_integer(),
            virtual_value: non_neg_integer()
          }

    @spec from_query(side, map()) :: t() | {:error, :parse_error}
    def from_query(side, %{"price" => price_str, "total" => total_str}) do
      with {price, ""} <- Decimal.parse(price_str),
           {total, ""} <- Integer.parse(total_str) do
        %__MODULE__{
          side: side,
          total: total,
          price: price,
          value: value(side, price, total),
          virtual_total: 0,
          virtual_value: 0
        }
      else
        _ -> {:error, :parse_error}
      end
    end

    def from_swap(bid, ask, side) do
      ask = round(ask * (1 - 0.0015))

      price =
        case side do
          :bid -> Decimal.div(Decimal.new(ask), Decimal.new(bid))
          :ask -> Decimal.div(Decimal.new(bid), Decimal.new(ask))
        end

      %__MODULE__{
        price: price,
        side: side,
        total: 0,
        value: 0,
        virtual_total: ask,
        virtual_value: Price.value(side, price, ask)
      }
    end

    def value(:ask, price, total) do
      total
      |> Decimal.new()
      |> Decimal.mult(price)
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()
    end

    def value(:bid, price, total) do
      total
      |> Decimal.new()
      |> Decimal.div(price)
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()
    end
  end

  defstruct [:id, :bids, :asks, :center, :spread]

  @type t :: %__MODULE__{
          id: String.t(),
          bids: list(Price.t()),
          asks: list(Price.t()),
          center: Decimal.t(),
          spread: Decimal.t()
        }

  @spec from_query(String.t(), map()) :: {:ok, __MODULE__.t()}
  def from_query(address, %{
        "base" => asks,
        "quote" => bids
      }) do
    {:ok,
     %__MODULE__{
       id: address,
       asks: Enum.map(asks, &Price.from_query(:ask, &1)),
       bids: Enum.map(bids, &Price.from_query(:bid, &1))
     }
     |> populate()}
  end

  def empty(address) do
    %__MODULE__{id: address, bids: [], asks: []}
  end

  def from_target(address), do: empty(address)

  def populate(%__MODULE__{asks: [ask | _], bids: [bid | _]} = book) do
    center =
      ask.price
      |> Decimal.add(bid.price)
      |> Decimal.div(Decimal.new(2))

    %{
      book
      | center: center,
        spread: ask.price |> Decimal.sub(bid.price) |> Decimal.div(center)
    }
  end

  def populate(book), do: book

  def merge(live, virtual) do
    %{
      virtual
      | asks: merge_prices(live.asks, virtual.asks),
        bids: merge_prices(live.bids, virtual.bids)
    }
    |> populate()
  end

  def from_pools(%{address: address, oracle_base: oracle_base, oracle_quote: oracle_quote}, limit)
      when is_binary(oracle_base) and is_binary(oracle_quote) do
    with {:ok, pool_base} <- Thorchain.pool_from_id(oracle_base),
         {:ok, pool_quote} <- Thorchain.pool_from_id(oracle_quote) do
      {x, y} = merge_pools(pool_base, pool_quote)

      {:ok,
       %__MODULE__{
         id: address,
         bids: from_pool({x, y}, :bid, limit),
         asks: from_pool({y, x}, :ask, limit)
       }
       |> populate()}
    else
      _ ->
        {:ok, empty(address)}
    end
  end

  def from_pools(%{address: address}, _) do
    {:ok, empty(address)}
  end

  def from_pool(pool, side, limit \\ 10) do
    # Size initial order based on min slip bps
    size = Thorchain.Swapper.calc_max_input(pool)
    # Collect cumulative
    for n <- 1..limit do
      {size * n, Thorchain.Swapper.process_swap(size * n, pool)}
    end
    # Split cumulative into discrete orders
    |> Enum.reduce({{0, 0}, []}, &to_discrete(&1, &2, side))
    |> elem(1)
    |> Enum.reverse()
  end

  defp to_discrete({bid, %{emit_assets: ask}}, {{bid_total, ask_total}, orders}, side) do
    {{bid, ask}, [Price.from_swap(bid - bid_total, ask - ask_total, side) | orders]}
  end

  defp merge_pools(b, q) when b.balance_rune > q.balance_rune do
    {round(b.balance_asset * q.balance_rune / b.balance_rune), q.balance_asset}
  end

  defp merge_pools(b, q) do
    {b.balance_asset, round(q.balance_asset * b.balance_rune / q.balance_rune)}
  end

  defp merge_prices(live, virtual) do
    Enum.concat(live, virtual)
    |> Enum.group_by(&{&1.price, &1.side})
    |> Enum.map(fn {{price, side}, items} ->
      Enum.reduce(
        items,
        %Price{price: price, side: side, total: 0, value: 0, virtual_total: 0, virtual_value: 0},
        fn el, acc ->
          %{
            acc
            | total: el.total + acc.total,
              value: el.value + acc.value,
              virtual_total: el.virtual_total + acc.virtual_total,
              virtual_value: el.virtual_value + acc.virtual_value
          }
        end
      )
    end)
    |> Enum.sort_by(
      & &1,
      &case &1.side do
        :ask -> Decimal.lte?(&1.price, &2.price)
        :bid -> Decimal.gte?(&1.price, &2.price)
      end
    )
  end
end
