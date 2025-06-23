defmodule Rujira.Chains.Base do
  @moduledoc """
  Implements the Base adapter for EVM compatibility.
  """
  @rpc "https://base-rpc.publicnode.com"
  @ws "wss://base-rpc.publicnode.com"

  use Rujira.Chains.Evm,
    rpc: @rpc,
    ws: @ws,
    asset: "BASE.ETH",
    chain: "base"
end
