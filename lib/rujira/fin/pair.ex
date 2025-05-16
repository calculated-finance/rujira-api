defmodule Rujira.Fin.Pair do
  alias Rujira.Assets
  alias Rujira.Fin.Book

  defstruct [
    :id,
    :address,
    :market_maker,
    :token_base,
    :token_quote,
    :oracle_base,
    :oracle_quote,
    :tick,
    :fee_taker,
    :fee_maker,
    :fee_address,
    :book,
    :history,
    :summary
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          market_maker: String.t(),
          token_base: String.t(),
          token_quote: String.t(),
          oracle_base: String.t(),
          oracle_quote: String.t(),
          tick: integer(),
          fee_taker: Decimal.t(),
          fee_maker: Decimal.t(),
          fee_address: String.t(),
          book: :not_loaded | Book.t()
        }

  @spec from_config(String.t(), map()) :: :error | {:ok, __MODULE__.t()}
  def from_config(address, %{
        "market_maker" => market_maker,
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
         market_maker: market_maker,
         token_base: Enum.at(denoms, 0),
         token_quote: Enum.at(denoms, 1),
         oracle_base: oracle_base,
         oracle_quote: oracle_quote,
         tick: tick,
         fee_taker: fee_taker,
         fee_maker: fee_maker,
         fee_address: fee_address,
         book: :not_loaded
       }}
    end
  end

  def get_asset(%{"chain" => chain, "symbol" => symbol}) do
    {:ok, String.upcase(chain) <> "." <> symbol}
  end

  def get_asset(nil), do: {:ok, nil}

  def init_msg(
        %{
          "denoms" => [x, y],
          "fee_address" => fee_address
        } = config
      ) do
    market_maker = Map.get(config, "market_maker")

    with {:ok, base} <- Assets.from_denom(x),
         {:ok, quote_} <- Assets.from_denom(y) do
      %{
        denoms: [x, y],
        oracles: [
          %{chain: String.downcase(base.chain), symbol: base.symbol},
          %{chain: String.downcase(quote_.chain), symbol: quote_.symbol}
        ],
        market_maker: market_maker,
        tick: 6,
        fee_taker: "0.0015",
        fee_maker: "0.00075",
        fee_address: fee_address
      }
    else
      _ ->
        %{
          denoms: [x, y],
          market_maker: market_maker,
          tick: 6,
          fee_taker: "0.0015",
          fee_maker: "0.00075",
          fee_address: fee_address
        }
    end
  end

  def migrate_msg(_from, _to, _), do: %{}

  def init_label(%{"denoms" => [x, y]}), do: "rujira-fin:#{x}:#{y}"
end
