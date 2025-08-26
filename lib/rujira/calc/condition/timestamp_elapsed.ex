defmodule Rujira.Calc.Condition.TimestampElapsed do
  @moduledoc """
  Condition type that triggers when a specific timestamp has elapsed.
  Currently a placeholder implementation.
  """
  defstruct []
  # TODO: implement from_config

  def from_config(_) do
    {:ok, %__MODULE__{}}
  end
end
