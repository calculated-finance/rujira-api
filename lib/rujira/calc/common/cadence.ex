defmodule Rujira.Calc.Common.Cadence do
  @moduledoc """
  Defines cadence types for scheduling Calc Protocol strategy executions.

  Cadences determine when and how often strategy conditions and actions should
  be evaluated and executed. Supports block-based, time-based, cron, and limit order cadences.
  """
  alias Rujira.Calc.Common.PriceStrategy

  defmodule Blocks do
    @moduledoc false
    defstruct [
      :interval,
      :previous
    ]

    @type t :: %__MODULE__{
            interval: non_neg_integer(),
            previous: non_neg_integer() | nil
          }
  end

  defmodule Time do
    @moduledoc false
    defstruct [
      :duration,
      :previous
    ]

    @type t :: %__MODULE__{
            duration: non_neg_integer(),
            previous: DateTime.t() | nil
          }
  end

  defmodule Cron do
    @moduledoc false
    defstruct [
      :expr,
      :previous
    ]

    @type t :: %__MODULE__{
            expr: String.t(),
            previous: DateTime.t() | nil
          }
  end

  defmodule LimitOrder do
    @moduledoc false

    alias Rujira.Calc.Common.PriceStrategy

    @type side :: :base | :quote

    defstruct pair_address: "", side: :base, strategy: PriceStrategy.default(), previous: nil
  end

  @type t :: Blocks.t() | Time.t() | Cron.t() | LimitOrder.t()

  def default, do: %Blocks{}

  def from_config(nil), do: {:ok, nil}

  def from_config(%{"blocks" => %{"interval" => interval} = map}) do
    previous = Map.get(map, "previous", nil)
    {:ok, %Blocks{interval: interval, previous: previous}}
  end

  def from_config(%{"time" => %{"duration" => %{"secs" => secs}} = map}) do
    case Map.get(map, "previous") do
      nil -> {:ok, %Time{duration: secs, previous: nil}}
      prev ->
        with {int, ""} <- Integer.parse(prev),
             {:ok, dt} <- DateTime.from_unix(int, :nanosecond) do
          {:ok, %Time{duration: secs, previous: dt}}
        end
    end
  end

  def from_config(%{"cron" => %{"expr" => expr} = map}) do
    case Map.get(map, "previous") do
      nil -> {:ok, %Cron{expr: expr, previous: nil}}
      prev ->
        with {int, ""} <- Integer.parse(prev),
             {:ok, dt} <- DateTime.from_unix(int, :nanosecond) do
          {:ok, %Cron{expr: expr, previous: dt}}
        end
    end
  end

  def from_config(%{
        "limit_order" =>
          %{"pair_address" => pair_address, "side" => side, "strategy" => strategy} = map
      }) do
    with {:ok, strategy} <- PriceStrategy.from_config(strategy) do
      previous = Map.get(map, "previous", nil)

      {:ok,
       %LimitOrder{pair_address: pair_address, side: side, strategy: strategy, previous: previous}}
    end
  end
end
