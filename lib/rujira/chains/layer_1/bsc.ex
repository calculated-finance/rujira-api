defmodule Rujira.Chains.Layer1.Bsc do
  defstruct rpc: "https://bnb.api.onfinality.io/public"
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Bsc do
  def balances(a, address) do
    Rujira.Chains.Layer1.Evm.balances(a.rpc, address, "BSC.BNB")
  end
end
