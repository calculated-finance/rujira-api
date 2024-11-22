defmodule Rujira.Chains.Native.Ltc do
  defstruct []
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chains.Native.Ltc do
  def balances(_a, _address) do
    {:ok, [%{amount: 1_000_000_000, asset: "LTC.LTC"}]}
  end
end
