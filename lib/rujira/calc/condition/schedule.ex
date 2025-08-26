defmodule Rujira.Calc.Condition.Schedule do
  @moduledoc """
  Condition type that triggers based on a cron-like scheduling expression.
  Currently a placeholder implementation.
  """
  defstruct []
  # TODO: implement from_config
  def from_config(_) do
    {:ok, %__MODULE__{}}
  end
end
