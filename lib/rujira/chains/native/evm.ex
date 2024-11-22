defmodule Rujira.Chains.Native.Evm do
  def balances(rpc, address, asset) do
    with {:ok, "0x" <> hex} <-
           Ethereumex.HttpClient.eth_get_balance(address, "latest", url: rpc) do
      {:ok, [%{asset: asset, amount: String.to_integer(hex, 16)}]}
    end
  end
end
