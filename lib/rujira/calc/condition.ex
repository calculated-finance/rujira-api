defmodule Rujira.Calc.Condition do
  @moduledoc """
  Condition node in a strategy execution flow that provides branching logic.
  """
  alias Rujira.Calc.Condition.BlocksCompleted
  alias Rujira.Calc.Condition.CanSwap
  alias Rujira.Calc.Condition.Schedule
  alias Rujira.Calc.Condition.TimestampElapsed

  defstruct [
    :condition,
    :index,
    :on_success,
    :on_failure
  ]

  @type t :: %__MODULE__{
          condition: BlocksCompleted | CanSwap | Schedule | TimestampElapsed,
          index: integer(),
          on_success: integer() | nil,
          on_failure: integer() | nil
        }

  def from_config(%{"blocks_completed" => msg}),
    do: BlocksCompleted.from_config(msg)

  def from_config(%{"can_swap" => msg}),
    do: CanSwap.from_config(msg)

  def from_config(%{"schedule" => msg}),
    do: Schedule.from_config(msg)

  def from_config(%{"timestamp_elapsed" => msg}),
    do: TimestampElapsed.from_config(msg)

  def from_config(_), do: {:error, :invalid_condition}
end
