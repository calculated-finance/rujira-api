defmodule Rujira.Bow.Account do
  alias Rujira.Bow.Xyk

  defstruct [
    :id,
    :pool,
    :account,
    :shares,
    :value
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          pool: Xyk.t(),
          account: String.t(),
          shares: non_neg_integer(),
          value: list(map())
        }
end
