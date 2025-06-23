defmodule Rujira.Chains.Bsc do
  @moduledoc """
  Implements the Binance Smart Chain adapter for EVM compatibility.
  """
  @rpc "https://bsc-rpc.publicnode.com"
  @ws "wss://bsc-rpc.publicnode.com"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws, asset: "BSC.BNB", chain: "bsc"
end
