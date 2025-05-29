defmodule Rujira.Fin.Book do
  defmodule Price do
    defstruct [:price, :total, :side, :value]

    @type side :: :bid | :ask
    @type t :: %__MODULE__{
            price: Decimal.t(),
            total: integer(),
            side: side,
            value: Decimal.t()
          }

    @spec from_query(side, map()) :: t() | {:error, :parse_error}
    def from_query(side, %{"price" => price_str, "total" => total_str}) do
      with {price, ""} <- Decimal.parse(price_str),
           {total, ""} <- Integer.parse(total_str) do
        %__MODULE__{
          side: side,
          total: total,
          price: price,
          value: value(side, price, total)
        }
      else
        _ -> {:error, :parse_error}
      end
    end

    def value(:ask, price, total) do
      total
      |> Decimal.new()
      |> Decimal.mult(price)
      |> Decimal.div(Decimal.new(1_000_000_000_000))
    end

    def value(:bid, price, total) do
      total
      |> Decimal.new()
      |> Decimal.div(price)
      |> Decimal.div(Decimal.new(1_000_000_000_000))
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

  def populate(%__MODULE__{asks: [ask | _], bids: [bid | _]} = book) do
    center = ask.price |> Decimal.add(bid.price) |> Decimal.div(Decimal.new(2))

    %{
      book
      | center: center,
        spread: ask.price |> Decimal.sub(bid.price) |> Decimal.div(center)
    }
  end

  def populate(book), do: book
end
