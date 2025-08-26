defmodule Rujira.Calc.Action.Swap do
  @moduledoc """
  Action type for executing token swaps between different denominations.
  Currently a placeholder implementation.
  """
  defstruct []

  # TODO: implement from_config
  def from_config(_) do
    {:ok, %__MODULE__{}}
  end
end
