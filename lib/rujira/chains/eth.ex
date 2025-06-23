defmodule Rujira.Chains.Eth do
  @moduledoc """
  Implements the Ethereum adapter for EVM compatibility.
  """
  @rpc "https://ethereum-rpc.publicnode.com"
  @ws "wss://ethereum-rpc.publicnode.com"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws, asset: "ETH.ETH", chain: "eth"
end
