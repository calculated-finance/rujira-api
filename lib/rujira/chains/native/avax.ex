defmodule Rujira.Chains.Native.Avax do
  defstruct rpc: "https://api.avax.network/ext/bc/C/rpc"
end

defimpl Rujira.Chains.Native.Adapter, for: Rujira.Chains.Native.Avax do
  def balances(a, address) do
    Rujira.Chains.Native.Evm.balances(a.rpc, address, "AVAX.AVAX")
  end
end
