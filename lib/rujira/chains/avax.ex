defmodule Rujira.Chains.Avax do
  @rpc "https://avalanche-c-chain-rpc.publicnode.com"
  @ws "wss://avalanche-c-chain-rpc.publicnode.com"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws, asset: "AVAX.AVAX", chain: "avax"
end
