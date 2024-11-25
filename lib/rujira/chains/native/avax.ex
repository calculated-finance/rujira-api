defmodule Rujira.Chains.Native.Avax do
  defstruct []

  def rpc() do
    "https://api.avax.network/ext/bc/C/rpc"
  end
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chain.Avax do
  def balances(a, address) do
    Rujira.Chains.Native.Evm.balances(a.rpc(), address, "AVAX.AVAX")
  end
end
