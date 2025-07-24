defmodule Rujira.Bow.Xyk do
  @moduledoc """
  Implements the XYK (Constant Product) automated market maker algorithm.
  """

  alias Rujira.Assets
  alias Rujira.Deployments.Target
  import Ecto.Query
  use Memoize

  @max_quotes 50

  defmodule Config do
    @moduledoc """
    Defines the configuration structure for an XYK liquidity pool.
    """
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
    @moduledoc """
    Defines the state structure for an XYK liquidity pool.
    """
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

    def from_target(address) do
      %__MODULE__{id: address, x: 0, y: 0, k: 0, shares: 0}
    end
  end

  defmodule Summary do
    @moduledoc """
    Defines the summary structure for an XYK liquidity pool.
    """
    alias Rujira.Assets
    alias Rujira.Bow.Xyk
    alias Rujira.Prices
    defstruct [:spread, :depth_bid, :depth_ask, :volume, :utilization]

    @type t :: %__MODULE__{
            spread: Decimal.t(),
            depth_bid: non_neg_integer(),
            depth_ask: non_neg_integer(),
            volume: non_neg_integer(),
            utilization: Decimal.t()
          }

    def load(%{address: address, config: config, state: state}) do
      with {:ok, volume} <- Xyk.volume(address),
           {:ok, asset_x} <- Assets.from_denom(config.x),
           {:ok, %{current: price_x}} <- Prices.get(asset_x.symbol),
           {:ok, asset_y} <- Assets.from_denom(config.y),
           {:ok, %{current: price_y}} <- Prices.get(asset_y.symbol),
           {low, mid, high} <- Xyk.limit(config, state) do
        spread = Decimal.div(Decimal.sub(high, low), mid)

        depth =
          Xyk.depth(config, state, Decimal.mult(Decimal.from_float(0.98), mid))
          |> Decimal.mult(price_y)
          |> Decimal.round()
          |> Decimal.to_integer()

        volume =
          volume
          |> Decimal.mult(price_y)
          |> Decimal.round()
          |> Decimal.to_integer()

        value =
          state.x
          |> Decimal.new()
          |> Decimal.mult(price_x)
          |> Decimal.add(
            state.y
            |> Decimal.new()
            |> Decimal.mult(price_y)
          )
          |> Decimal.round()
          |> Decimal.to_integer()

        utilization = Decimal.div(volume, value)

        {:ok,
         %__MODULE__{
           spread: spread,
           depth_bid: depth,
           depth_ask: depth,
           volume: volume,
           utilization: utilization
         }}
      else
        nil -> {:ok, nil}
        other -> other
      end
    end
  end

  defstruct [:id, :address, :config, :state, :deployment_status]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          config: Config.t(),
          state: State.t(),
          deployment_status: Target.status()
        }

  def from_target(%Target{
        address: address,
        config: %{"strategy" => %{"xyk" => q}},
        status: status
      }) do
    with %{
           strategy: %{
             xyk: %{x: x, y: y, step: step, min_quote: min_quote, fee: fee}
           },
           metadata: %{display: denom}
         } <- init_msg(q),
         {step, ""} <- Decimal.parse(step),
         {fee, ""} <- Decimal.parse(fee),
         {min_quote, ""} <- Integer.parse(min_quote) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         config: %Config{
           x: x,
           y: y,
           step: step,
           share_denom: denom,
           min_quote: min_quote,
           fee: fee
         },
         state: State.from_target(address),
         deployment_status: status
       }}
    end
  end

  def from_query(address, [config, state]) do
    with {:ok, config} <- Config.from_query(config),
         {:ok, state} <- State.from_query(address, state) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         config: config,
         state: state,
         deployment_status: :live
       }}
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

  def limit(_, %{k: 0}), do: nil

  def limit(config, state) do
    {bid, ask, _} = do_quote(config, state)
    low = Decimal.div(ask, bid)
    {bid, ask, _} = do_quote(config, %{state | x: state.y, y: state.x})
    high = Decimal.div(bid, ask)
    mid = Decimal.div(Decimal.add(high, low), Decimal.new(2))
    {low, mid, high}
  end

  defmemo do_quote(config, state) do
    bid =
      state.x
      |> Decimal.new()
      |> Decimal.mult(config.step)
      |> Decimal.round()
      |> Decimal.to_integer()

    x = state.x + bid
    y_cur = state.y

    y_new =
      Decimal.to_integer(Decimal.round(Decimal.div(Decimal.new(state.k), Decimal.new(x))))

    ask_total = y_cur - y_new
    y = y_cur - ask_total

    fee_amount =
      Decimal.mult(Decimal.new(ask_total), config.fee)
      |> Decimal.round()
      |> Decimal.to_integer()
      |> then(&(&1 + 1))

    ask = ask_total - fee_amount
    {bid, ask, %{state | x: x, y: y, k: x * y}}
  end

  defmemo depth(config, state, threshold, value \\ 0) do
    {bid, ask, state} = do_quote(config, state)

    case Decimal.compare(Decimal.div(ask, bid), threshold) do
      :lt ->
        value

      _ ->
        depth(config, state, threshold, Decimal.add(value, ask))
    end
  end

  def do_quotes(config, state, side) do
    do_quotes(config, state, side, [], 0)
    |> Enum.reverse()
  end

  defp do_quotes(_config, _state, _side, acc, count) when count >= @max_quotes do
    acc
  end

  defp do_quotes(_config, %{shares: 0}, _side, _, _), do: []

  defp do_quotes(config, state, side, acc, count) do
    {x, y, new_state} = quote_for(side, config, state)
    price = get_price(side, x, y)
    total = y |> Decimal.round() |> Decimal.to_integer()

    entry = %{
      price: price,
      total: total,
      side: Atom.to_string(side),
      value: value(side, price, total)
    }

    do_quotes(config, new_state, side, [entry | acc], count + 1)
  end

  defp quote_for(:ask, config, state) do
    # flip X↔Y, ask side does the right thing, then flip result back
    {y, x, %{x: y1, y: x1, k: k1}} =
      do_quote(config, %{x: state.y, y: state.x, k: state.k})

    # now bid_x was ΔY, ask_y was ΔX in flipped-land → swap them
    {y, x, %{state | x: x1, y: y1, k: k1}}
  end

  defp quote_for(:bid, config, state), do: do_quote(config, state)

  defp get_price(:ask, _, 0), do: Decimal.new(0)
  defp get_price(:bid, _, 0), do: Decimal.new(0)
  defp get_price(:ask, x, y), do: Decimal.div(x, y)
  defp get_price(:bid, x, y), do: Decimal.div(y, x)

  defp value(:ask, price, total) do
    total
    |> Decimal.new()
    |> Decimal.mult(price)
    |> Decimal.div(Decimal.new(1_000_000_000_000))
  end

  defp value(:bid, price, total) do
    total
    |> Decimal.new()
    |> Decimal.div(price)
    |> Decimal.div(Decimal.new(1_000_000_000_000))
  end

  def init_msg(%{"x" => x, "y" => y} = params) do
    {:ok, x_asset} = Assets.from_denom(x)
    {:ok, y_asset} = Assets.from_denom(y)
    step = Map.get(params, "step", "0.001")
    min_quote = Map.get(params, "min_quote", "10000")
    fee = Map.get(params, "fee", "0.003")

    %{
      strategy: %{
        xyk: %{
          x: x,
          y: y,
          step: step,
          min_quote: min_quote,
          fee: fee
        }
      },
      metadata: %{
        description:
          "Transferable shares issued when depositing funds into the Rujira XYK #{Assets.short_id(x_asset)}/#{Assets.short_id(y_asset)} liquidity pool",
        display: "x/bow-xyk-#{x}-#{y}",
        name: "#{Assets.short_id(x_asset)}/#{Assets.short_id(y_asset)} XYK LP Shares",
        symbol: "LP-#{Assets.short_id(x_asset)}/#{Assets.short_id(y_asset)}-XYK"
      }
    }
  end

  def migrate_msg(_from, _to, _), do: %{}

  def init_label(_, %{"x" => x, "y" => y}), do: "rujira-bow:#{x}-#{y}:xyk"
end
