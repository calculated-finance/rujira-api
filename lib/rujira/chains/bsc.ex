defmodule Rujira.Chains.Bsc do
  @moduledoc """
  Implements the Binance Smart Chain adapter for EVM compatibility.
  """
  @rpc "https://bnb-mainnet.g.alchemy.com/v2/"
  @ws "wss://bnb-mainnet.g.alchemy.com/v2/"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws, asset: "BSC.BNB", chain: "bsc"
end
