defmodule Rujira.Chains.Base do
  @moduledoc """
  Implements the Base adapter for EVM compatibility.
  """
  @rpc "https://base-mainnet.g.alchemy.com/v2/"
  @ws "wss://base-mainnet.g.alchemy.com/v2/"

  use Rujira.Chains.Evm,
    rpc: @rpc,
    ws: @ws,
    asset: "BASE.ETH",
    chain: "base"
end
