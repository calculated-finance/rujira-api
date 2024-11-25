defmodule Rujira.Chains.Native.Thor do
  defstruct []
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chains.Native.Thor do
  # Empty balance to prevent duplication of RUNE on the account balances query
  def balances(_a, _address), do: {:ok, []}
end
