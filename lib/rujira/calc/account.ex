defmodule Rujira.Calc.Account do
  @moduledoc """
    A single calc account, powered by Rujira.Calc.Strategy contracts. includes all the strategies for a single account
  """
  alias Rujira.Calc.Strategy

  defstruct [:id, :address, :strategies]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          strategies: [Strategy.t()]
        }
end
