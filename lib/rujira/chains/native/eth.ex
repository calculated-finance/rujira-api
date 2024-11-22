defmodule Rujira.Chains.Native.Eth do
  defstruct []

  def rpc() do
    "https://ethereum-rpc.publicnode.com"
  end
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chain.Eth do
  def balances(a, address) do
    Rujira.Chains.Native.Evm.balances(a.rpc(), address, "ETH.ETH")
  end
end
