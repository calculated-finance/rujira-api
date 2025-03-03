defmodule Rujira.Chains.Bsc do
  @rpc "https://bsc-rpc.publicnode.com"
  @ws "wss://bsc-rpc.publicnode.com"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Bsc do
  alias Rujira.Assets

  def balances(a, address, assets) do
    with {_native_asset, other_assets} <- Enum.split_with(assets, &(&1 == "BSC.BNB")),
         {:ok, native_balance} <-
           a.native_balance(address),
         {:ok, assets_balance} <-
           a.balances_of(address, other_assets) do
      {:ok, [%{asset: Assets.from_string("BSC.BNB"), amount: native_balance} | assets_balance]}
    end
  end
end
