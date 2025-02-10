defmodule Rujira.Fin.Pair do
  alias Rujira.Fin.Book

  defmodule Status do
    defstruct [
      :status,
      :price
    ]

    @type(status :: :active, :paused)
    @type t :: %__MODULE__{
            status: status,
            price: Decimal.t() | nil
          }

    @spec from_query(map()) ::
            {:error, :parse_error} | {:ok, :paused | Rujira.Fin.Pair.Status.t()}
    def from_query(%{"active" => %{"price" => price}}) do
      with {price, ""} <- Decimal.parse(price) do
        {:ok, %__MODULE__{status: :active, price: price}}
      else
        _ -> {:error, :parse_error}
      end
    end

    def from_query(%{"paused" => _}), do: {:ok, %__MODULE__{status: :paused, price: nil}}
  end

  defstruct [
    :id,
    :address,
    :token_base,
    :token_quote,
    :oracle_base,
    :oracle_quote,
    :tick,
    :fee_taker,
    :fee_maker,
    :fee_address,
    :status,
    :book,
    :history,
    :summary
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          token_base: String.t(),
          token_quote: String.t(),
          oracle_base: String.t(),
          oracle_quote: String.t(),
          tick: integer(),
          fee_taker: Decimal.t(),
          fee_maker: Decimal.t(),
          fee_address: String.t(),
          status: :not_loaded | Status.t(),
          book: :not_loaded | Book.t()
        }

  @spec from_config(String.t(), map()) :: :error | {:ok, __MODULE__.t()}
  def from_config(address, %{
        "denoms" => denoms,
        "oracles" => oracles,
        "tick" => tick,
        "fee_taker" => fee_taker,
        "fee_maker" => fee_maker,
        "fee_address" => fee_address
      }) do
    with {fee_taker, ""} <- Decimal.parse(fee_taker),
         {fee_maker, ""} <- Decimal.parse(fee_maker),
         {:ok, oracle_base} <- get_asset(Enum.at(oracles || [], 0)),
         {:ok, oracle_quote} <- get_asset(Enum.at(oracles || [], 1)) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         token_base: Enum.at(denoms, 0),
         token_quote: Enum.at(denoms, 1),
         oracle_base: oracle_base,
         oracle_quote: oracle_quote,
         tick: tick,
         fee_taker: fee_taker,
         fee_maker: fee_maker,
         fee_address: fee_address,
         status: :not_loaded,
         book: :not_loaded
       }}
    end
  end

  def get_asset(%{"chain" => chain, "symbol" => symbol}) do
    {:ok, String.upcase(chain) <> "." <> symbol}
  end

  def get_asset(nil), do: {:ok, nil}
end
