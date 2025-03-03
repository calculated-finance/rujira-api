defmodule Rujira.Chains.Bsc do
  @rpc "https://bsc-rpc.publicnode.com"
  @ws "wss://bsc-rpc.publicnode.com"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws, asset: "BSC.BNB"
end
