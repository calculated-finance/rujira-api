defmodule Rujira.Chains.Layer1.Avax do
  defstruct rpc: "https://api.avax.network/ext/bc/C/rpc"
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Avax do
  def balances(a, address) do
    Rujira.Chains.Layer1.Evm.balances(a.rpc, address, "AVAX.AVAX")
  end
end
