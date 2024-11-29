defmodule Rujira.Chains.Layer1.Kuji do
  defstruct []
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Kuji do
  # TODO: Populate with Kujira merge assets
  def balances(_a, _address), do: {:ok, []}
end
