defmodule Rujira.Index.Account do
  alias Rujira.Index.Vault

  defstruct [
    :id,
    :index,
    :account,
    :shares,
    :shares_value
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          index: Vault.t(),
          account: String.t(),
          shares: non_neg_integer(),
          shares_value: Decimal.t()
        }
end
