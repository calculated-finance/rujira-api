defmodule Rujira.Calc.Manager do
  @moduledoc """
    On chain Manager for Rujira.Calc.Strategy
  """

  defstruct [:address, :fee_collector, :strategy_code_id]

  def from_config(address, %{
        "fee_collector" => fee_collector,
        "strategy_code_id" => strategy_code_id
      }) do
    {:ok,
     %__MODULE__{
       address: address,
       fee_collector: fee_collector,
       strategy_code_id: strategy_code_id
     }}
  end

  def init_msg(msg), do: msg
  def migrate_msg(_from, _to, _), do: %{}
  def init_label(_, _), do: "calc:manager"
end
