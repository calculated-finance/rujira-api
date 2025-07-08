defmodule Rujira.Chains.Cosmos do
  @moduledoc """
  Simple structure for Cosmos accounts.
  """
  defstruct [:id, :chain, :address]

  def account_from_id(id) do
    [chain, account] = String.split(id, ":")
    {:ok, %__MODULE__{id: id, chain: String.to_existing_atom(chain), address: account}}
  end
end
