defmodule Rujira.Calc.Condition.Schedule do
  @moduledoc """
  Condition type that triggers based on a cron-like scheduling expression.
  Currently a placeholder implementation.
  """
  alias Rujira.Assets.Coin
  alias Rujira.Calc.Common.Cadence

  # default values
  defstruct scheduler_address: "",
            manager_address: "",
            cadence: Cadence.default(),
            next: nil,
            execution_rebate: [],
            executors: [],
            jitter: 0

  @type t :: %__MODULE__{
          scheduler_address: String.t(),
          manager_address: String.t(),
          cadence: Cadence.t(),
          next: Cadence.t() | nil,
          execution_rebate: list(Coin.t()),
          executors: [String.t()],
          jitter: non_neg_integer()
        }

  def from_config(%{
        "scheduler_address" => scheduler_address,
        "manager_address" => manager_address,
        "cadence" => cadence,
        "next" => next,
        "execution_rebate" => execution_rebate,
        "executors" => executors,
        "jitter" => jitter
      }) do
    with {:ok, cadence} <- Cadence.from_config(cadence),
         {:ok, next} <- Cadence.from_config(next),
         {:ok, execution_rebate} <- Rujira.Enum.reduce_while_ok(execution_rebate, &Coin.parse/1) do
      {:ok,
       %__MODULE__{
         scheduler_address: scheduler_address,
         manager_address: manager_address,
         cadence: cadence,
         next: next,
         execution_rebate: execution_rebate,
         executors: executors,
         jitter: jitter
       }}
    end
  end

  # default values
  def from_config(_), do: {:ok, %__MODULE__{}}
end
