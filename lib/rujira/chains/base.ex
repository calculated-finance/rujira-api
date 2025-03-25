defmodule Rujira.Chains.Base do
  @rpc "https://base-rpc.publicnode.com"
  @ws "wss://base-rpc.publicnode.com"

  use Rujira.Chains.Evm,
    rpc: @rpc,
    ws: @ws,
    asset: "BASE.ETH",
    addresses: [
      "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
      "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
    ]
end
