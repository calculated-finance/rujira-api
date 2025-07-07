defmodule Rujira.Chains.Avax do
  @moduledoc """
  Implements the Avalanche C-Chain adapter for EVM compatibility.
  """
  @rpc "https://avax-mainnet.g.alchemy.com/v2/"
  @ws "wss://avax-mainnet.g.alchemy.com/v2/"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws, asset: "AVAX.AVAX", chain: "avax"
end
