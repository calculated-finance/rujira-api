defmodule Rujira.Bow.Xyk do
  defmodule Config do
    defstruct [:x, :y, :step, :min_quote, :share_denom, :fee]

    @type t :: %__MODULE__{
            # Denom string of the x asset
            x: String.t(),
            # Denom string of the y asset
            y: String.t(),
            # Step
            step: Decimal,
            share_denom: String.t(),
            # The minimum number that X and Y must meet in order to quote a price
            min_quote: non_neg_integer(),
            # The fee that's charged on each quote and required to be paid
            # in `validate` function
            fee: Decimal.t()
          }

    def from_query(%{"x" => x, "y" => y, "step" => step, "min_quote" => min_quote, "fee" => fee}) do
      with {step, ""} <- Decimal.parse(step),
           {fee, ""} <- Decimal.parse(fee),
           {min_quote, ""} <- Integer.parse(min_quote) do
        {:ok,
         %__MODULE__{
           x: x,
           y: y,
           step: step,
           share_denom: "x/bow-xyk-#{x}-#{y}",
           min_quote: min_quote,
           fee: fee
         }}
      end
    end
  end

  defmodule State do
    defstruct [:id, :x, :y, :k, :shares]

    @type t :: %__MODULE__{
            id: String.t(),
            # Balance of the x token
            x: non_neg_integer(),
            # Balance of the y token
            y: non_neg_integer(),
            # x * y
            k: non_neg_integer(),
            # Number of ownership share tokens issued
            shares: non_neg_integer()
          }

    def from_query(address, %{"x" => x, "y" => y, "k" => k, "shares" => shares}) do
      with {x, ""} <- Integer.parse(x),
           {y, ""} <- Integer.parse(y),
           {k, ""} <- Integer.parse(k),
           {shares, ""} <- Integer.parse(shares) do
        {:ok, %__MODULE__{id: address, x: x, y: y, k: k, shares: shares}}
      end
    end
  end

  defmodule Summary do
    alias Rujira.Prices
    alias Rujira.Assets
    import Ecto.Query
    defstruct [:spread, :depth_bid, :depth_ask, :volume, :utilization]

    @type t :: %__MODULE__{
            spread: Decimal.t(),
            depth_bid: non_neg_integer(),
            depth_ask: non_neg_integer(),
            volume: non_neg_integer(),
            utilization: Decimal.t()
          }

    def load(%{address: address, config: %{step: step, fee: fee} = config, state: state}) do
      with {:ok, trades} <- Rujira.Bow.list_trades_query(address),
           {:ok, asset_x} <- Assets.from_denom(config.x),
           {:ok, price_x} <- Prices.get(asset_x.symbol),
           {:ok, asset_y} <- Assets.from_denom(config.y),
           {:ok, price_y} <- Prices.get(asset_y.symbol) do
        volume =
          trades
          |> where([t], fragment("? > NOW () - '1 day'::interval", t.timestamp))
          |> subquery()
          |> select([t], sum(t.quote_amount))
          |> Rujira.Repo.one()
          |> Decimal.mult(price_y.price)
          |> Decimal.round()
          |> Decimal.to_integer()

        value =
          state.x
          |> Decimal.new()
          |> Decimal.mult(price_x.price)
          |> Decimal.add(
            state.y
            |> Decimal.new()
            |> Decimal.mult(price_y.price)
          )
          |> Decimal.round()
          |> Decimal.to_integer()

        utilization = Decimal.div(volume, value)

        {:ok,
         %Rujira.Bow.Xyk.Summary{
           spread: Rujira.Bow.Xyk.spread(config, state),
           depth_bid: 10_000_000_000,
           depth_ask: 10_000_000_000,
           volume: volume,
           utilization: utilization
         }}
      end
    end
  end

  defstruct [:id, :address, :config, :state]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          config: Config.t(),
          state: State.t()
        }

  def from_query(address, [config, state]) do
    with {:ok, config} <- Config.from_query(config),
         {:ok, state} <- State.from_query(address, state) do
      {:ok, %__MODULE__{id: address, address: address, config: config, state: state}}
    end
  end

  def spread(config, state) do
    bid = state.x |> Decimal.new() |> Decimal.mult(config.step)

    ask =
      state.k
      |> Decimal.new()
      |> Decimal.div(Decimal.sub(Decimal.new(state.x), bid))
      |> Decimal.sub(Decimal.new(state.y))
      |> Decimal.mult(Decimal.add(Decimal.new(1), config.fee))

    high = Decimal.div(ask, bid)

    ask = state.y |> Decimal.new() |> Decimal.mult(config.step)

    bid =
      state.k
      |> Decimal.new()
      |> Decimal.div(Decimal.sub(Decimal.new(state.y), ask))
      |> Decimal.sub(Decimal.new(state.x))
      |> Decimal.mult(Decimal.add(Decimal.new(1), config.fee))

    low = Decimal.div(ask, bid)
    mid = Decimal.div(Decimal.add(high, low), Decimal.new(2))
    Decimal.div(Decimal.sub(high, low), mid)
  end
end
