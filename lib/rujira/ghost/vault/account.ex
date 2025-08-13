defmodule Rujira.Ghost.Vault.Account do
  @moduledoc """
  Defines structure of a user's deposit into a Ghost lending vault
  """
  alias Rujira.Ghost.Vault
  defstruct [:id, :account, :vault, :shares, :value]

  @type t :: %__MODULE__{
          id: String.t(),
          vault: Vault.t(),
          account: String.t(),
          shares: non_neg_integer(),
          value: non_neg_integer()
        }
end
