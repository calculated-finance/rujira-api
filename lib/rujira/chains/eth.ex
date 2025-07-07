defmodule Rujira.Chains.Eth do
  @moduledoc """
  Implements the Ethereum adapter for EVM compatibility.
  """
  @rpc "https://eth-mainnet.g.alchemy.com/v2/"
  @ws "wss://eth-mainnet.g.alchemy.com/v2/"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws, asset: "ETH.ETH", chain: "eth"
end
