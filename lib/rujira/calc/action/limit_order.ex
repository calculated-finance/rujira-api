defmodule Rujira.Calc.Action.LimitOrder do
  @moduledoc """
  Action type for executing limit orders with specified price conditions.
  Currently a placeholder implementation.
  """
  defstruct []
  # TODO: implement from_config

  def from_config(_) do
    {:ok, %__MODULE__{}}
  end
end
