defmodule Rujira.Chains.Layer1.Kuji do
  defstruct []
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Kuji do
  def balances(_a, _address, _assets), do: {:ok, []}
end
