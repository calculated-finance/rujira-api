defmodule Rujira.Bow.Xyk do
  alias Rujira.Assets
  import Ecto.Query
  use Memoize

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
    defstruct [:spread, :depth_bid, :depth_ask, :volume, :utilization]

    @type t :: %__MODULE__{
            spread: Decimal.t(),
            depth_bid: non_neg_integer(),
            depth_ask: non_neg_integer(),
            volume: non_neg_integer(),
            utilization: Decimal.t()
          }

    def load(%{address: address, config: config, state: state}) do
      with {:ok, volume} <- Rujira.Bow.Xyk.volume(address),
           {:ok, asset_x} <- Assets.from_denom(config.x),
           {:ok, price_x} <- Prices.get(asset_x.symbol),
           {:ok, asset_y} <- Assets.from_denom(config.y),
           {:ok, price_y} <- Prices.get(asset_y.symbol),
           {low, mid, high} <- Rujira.Bow.Xyk.limit(config, state) do
        spread = Decimal.div(Decimal.sub(high, low), mid)

        depth =
          Rujira.Bow.Xyk.depth(config, state, Decimal.mult(Decimal.from_float(1.02), mid))
          |> Decimal.mult(price_y.price)
          |> Decimal.round()
          |> Decimal.to_integer()

        volume =
          volume
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
           spread: spread,
           depth_bid: depth,
           depth_ask: depth,
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

  def volume(address) do
    with {:ok, trades} <- Rujira.Bow.list_trades_query(address) do
      {:ok,
       trades
       |> where([t], fragment("? > NOW () - '1 day'::interval", t.timestamp))
       |> subquery()
       |> select([t], fragment("COALESCE(?, 0)", sum(t.quote_amount)))
       |> Rujira.Repo.one()}
    end
  end

  def limit(config, state) do
    {bid, ask, _} = do_quote(config, state)
    high = Decimal.div(ask, bid)
    {bid, ask, _} = do_quote(config, %{state | x: state.y, y: state.x})
    low = Decimal.div(bid, ask)
    mid = Decimal.div(Decimal.add(high, low), Decimal.new(2))
    {low, mid, high}
  end

  defmemo do_quote(config, state) do
    bid = state.x |> Decimal.new() |> Decimal.mult(config.step)

    ask =
      state.k
      |> Decimal.new()
      |> Decimal.div(Decimal.sub(Decimal.new(state.x), bid))
      |> Decimal.sub(Decimal.new(state.y))
      |> Decimal.mult(Decimal.add(Decimal.new(1), config.fee))

    x = bid |> Decimal.round() |> Decimal.to_integer() |> then(&(state.x - &1))
    y = ask |> Decimal.round() |> Decimal.to_integer() |> then(&(state.y + &1))

    {bid, ask, %{state | x: x, y: y, k: x * y}}
  end

  defmemo depth(config, state, threshold, value \\ 0) do
    {bid, ask, state} = do_quote(config, state)

    case Decimal.compare(Decimal.div(ask, bid), threshold) do
      :gt ->
        value

      _ ->
        depth(config, state, threshold, Decimal.add(value, ask))
    end
  end

  def init_msg(%{"x" => x, "y" => y}) do
    {:ok, x_asset} = Assets.from_denom(x)
    {:ok, y_asset} = Assets.from_denom(y)

    %{
      strategy: %{
        xyk: %{
          x: x,
          y: y,
          step: "0.001",
          min_quote: "10000",
          fee: "0.003"
        }
      },
      metadata: %{
        description:
          "Transferable shares issued when depositing funds into the Rujira XYK #{Assets.short_id(x_asset)}/#{Assets.short_id(y_asset)} liquidity pool",
        display: "x/bow-xyk-#{x}-#{y}",
        name: "#{Assets.short_id(x_asset)}/#{Assets.short_id(y_asset)} XYK Liquidity Shares",
        symbol: "LP-#{Assets.short_id(x_asset)}/#{Assets.short_id(y_asset)}-XYK"
      }
    }
  end

  def migrate_msg(_from, _to, _), do: %{}

  def init_label(%{"x" => x, "y" => y}), do: "rujira-bow:#{x}-#{y}:xyk"
end
