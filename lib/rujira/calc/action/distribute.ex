defmodule Rujira.Calc.Action.Distribute do
  @moduledoc """
  Action type for distributing assets to multiple recipients.
  Currently a placeholder implementation.
  """
  defstruct []
  # TODO: implement from_config

  def from_config(_) do
    {:ok, %__MODULE__{}}
  end
end
