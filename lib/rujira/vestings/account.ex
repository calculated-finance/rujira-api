defmodule Rujira.Vestings.Account do
  @moduledoc """
  A single vesting account, powered by DaoDao vesting contracts. includes all the vesting contracts for a single account
  """
  defstruct [:id, :address, :vestings]
  alias Rujira.Vestings.Vesting

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          vestings: list(Vesting.t())
        }
end
