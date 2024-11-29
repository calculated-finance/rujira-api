defmodule Rujira.Chains.Layer1.Thor do
  defstruct []
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Thor do
  # Empty balance to prevent duplication of RUNE on the account balances query
  def balances(_a, _address), do: {:ok, []}
end
