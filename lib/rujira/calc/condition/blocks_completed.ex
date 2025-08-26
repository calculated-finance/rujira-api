defmodule Rujira.Calc.Condition.BlocksCompleted do
  @moduledoc """
  Condition type that triggers after a specified number of blocks have elapsed.
  Currently a placeholder implementation.
  """
  defstruct []
  # TODO: implement from_config

  def from_config(_) do
    {:ok, %__MODULE__{}}
  end
end
