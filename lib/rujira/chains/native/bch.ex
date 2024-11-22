defmodule Rujira.Chains.Native.Bch do
  defstruct []
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chains.Native.Bch do
  def balances(_a, _address) do
    {:ok, [%{amount: 1_000_000_000, asset: "BCH.BCH"}]}
  end
end
