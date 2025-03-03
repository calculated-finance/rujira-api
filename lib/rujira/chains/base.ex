defmodule Rujira.Chains.Base do
  @rpc "https://base-rpc.publicnode.com"
  @ws "wss://base-rpc.publicnode.com"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws, asset: "BASE.ETH"
end
