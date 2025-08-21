defmodule Rujira.Calc.Scheduler do
  @moduledoc """
    On chain Scheduler for Rujira.Calc.Strategy
  """
  defstruct [:address]

  def init_msg(msg), do: msg
  def migrate_msg(_from, _to, _), do: %{}
  def init_label(_, _), do: "calc:scheduler"
end
