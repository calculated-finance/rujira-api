defmodule Rujira.Chains.Native.Doge do
  defstruct []
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chains.Native.Doge do
  def balances(_a, _address) do
    {:ok, [%{amount: 1_000_000_000, asset: "DOGE.DOGE"}]}
  end
end
