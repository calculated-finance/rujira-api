defmodule Rujira.Chains.Layer1.Eth do
  defstruct rpc: "https://ethereum-rpc.publicnode.com"
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Eth do
  def balances(a, address) do
    Rujira.Chains.Layer1.Evm.balances(a.rpc, address, "ETH.ETH")
  end
end
