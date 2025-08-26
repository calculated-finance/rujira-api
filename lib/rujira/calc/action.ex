defmodule Rujira.Calc.Action do
  @moduledoc """
  Single node of a strategy
  """
  alias Rujira.Calc.Action.Distribute
  alias Rujira.Calc.Action.LimitOrder
  alias Rujira.Calc.Action.Swap

  defstruct [
    :action,
    :index,
    :next
  ]

  @type t :: %__MODULE__{
          action: Distribute | LimitOrder | Swap,
          index: integer(),
          next: integer() | nil
        }

  def from_config(%{"distribute" => msg}),
    do: Distribute.from_config(msg)

  def from_config(%{"limit_order" => msg}),
    do: LimitOrder.from_config(msg)

  def from_config(%{"swap" => msg}),
    do: Swap.from_config(msg)

  def from_config(_), do: {:error, :invalid_action}
end
