defmodule Rujira.Calc.Common.Cadence do
  alias Rujira.Calc.Common.PriceStrategy

  defmodule Blocks do
    @moduledoc false
    defstruct [interval: 0 , previous: nil]
  end

  defmodule Time do
    @moduledoc false
    defstruct [duration: 0, previous: nil]
  end

  defmodule Cron do
    @moduledoc false
    defstruct [expr: "", previous: nil]
  end

  defmodule LimitOrder do
    @moduledoc false

    alias Rujira.Calc.Common.PriceStrategy

    @type side :: :base | :quote

    defstruct [pair_address: "", side: :base, strategy: PriceStrategy.default(), previous: nil]
  end

  @type t :: Blocks.t() | Time.t() | Cron.t() | LimitOrder.t()

  def default, do: %Blocks{}

  def from_config(nil), do: {:ok, nil}

  def from_config(%{"blocks" => %{"interval" => interval} = map}) do
    previous = Map.get(map, "previous", nil)
    {:ok, %Blocks{interval: interval, previous: previous}}
  end

  def from_config(%{"time" => %{"duration" => duration} = map}) do
    previous = Map.get(map, "previous", nil)
    {:ok, %Time{duration: duration, previous: previous}}
  end

  def from_config(%{"cron" => %{"expr" => expr} = map}) do
    previous = Map.get(map, "previous", nil)
    {:ok, %Cron{expr: expr, previous: previous}}
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
