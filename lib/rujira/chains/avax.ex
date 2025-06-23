defmodule Rujira.Chains.Avax do
  @moduledoc """
  Implements the Avalanche C-Chain adapter for EVM compatibility.
  """
  @rpc "https://avalanche-c-chain-rpc.publicnode.com"
  @ws "wss://avalanche-c-chain-rpc.publicnode.com"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws, asset: "AVAX.AVAX", chain: "avax"
end
