defmodule Rujira.Chains.Native.Eth do
  defstruct rpc: "https://ethereum-rpc.publicnode.com"
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chains.Native.Eth do
  def balances(a, address) do
    Rujira.Chains.Native.Evm.balances(a.rpc, address, "ETH.ETH")
  end
end
