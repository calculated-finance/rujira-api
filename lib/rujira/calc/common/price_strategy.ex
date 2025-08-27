defmodule Rujira.Calc.Common.PriceStrategy do
  @moduledoc """
  Defines price strategy types for Calc Protocol actions.

  Price strategies determine how prices are calculated for limit orders and other
  price-dependent operations. Supports fixed prices and offset-based pricing.
  """

  defmodule Fixed do
    @moduledoc "Fixed price strategy with a static price value."
    defstruct price: 0.0

    @type t :: %__MODULE__{price: float()}
  end

  defmodule Offset do
    @moduledoc "Offset-based price strategy with directional pricing from a base price."
    defstruct side: :base, direction: :above, offset: 0.0, tolerance: nil

    @type side :: :base | :quote
    @type direction :: :above | :below

    @type t :: %__MODULE__{
            side: side,
            direction: direction,
            offset: float(),
            tolerance: float() | nil
          }
  end

  @type t :: Fixed.t() | Offset.t()

  def default, do: %Fixed{}

  def from_config(%{"fixed" => price}) do
    {:ok, %Fixed{price: price}}
  end

  def from_config(%{
        "offset" => %{"side" => side, "direction" => direction, "offset" => offset} = map
      }) do
    with {:ok, side} <- parse_side(side),
         {:ok, direction} <- parse_direction(direction) do
      tolerance = Map.get(map, "tolerance", nil)
      {:ok, %Offset{side: side, direction: direction, offset: offset, tolerance: tolerance}}
    end
  end

  def parse_side("base"), do: {:ok, :base}
  def parse_side("quote"), do: {:ok, :quote}
  def parse_side(_), do: {:error, :invalid_side}

  def parse_direction("above"), do: {:ok, :above}
  def parse_direction("below"), do: {:ok, :below}
  def parse_direction(_), do: {:error, :invalid_direction}
end
