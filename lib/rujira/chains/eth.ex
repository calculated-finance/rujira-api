defmodule Rujira.Chains.Eth do
  @rpc "https://ethereum-rpc.publicnode.com"
  @ws "wss://ethereum-rpc.publicnode.com"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws, asset: "ETH.ETH", chain: "eth"
end
