defmodule Rujira.Chains.Native.Kuji do
  defstruct []
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chains.Native.Kuji do
  # TODO: Populate with Kujira merge assets
  def balances(_a, _address), do: {:ok, []}
end
