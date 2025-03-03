defmodule Rujira.Chains.Eth do
  @rpc "https://ethereum-rpc.publicnode.com"
  @ws "wss://ethereum-rpc.publicnode.com"

  use Rujira.Chains.Evm, rpc: @rpc, ws: @ws
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Eth do
  alias Rujira.Assets

  def balances(a, address, assets) do
    with {_native_asset, other_assets} <- Enum.split_with(assets, &(&1 == "ETH.ETH")),
         {:ok, native_balance} <-
           a.native_balance(address),
         {:ok, assets_balance} <-
           a.balances_of(address, other_assets) do
      {:ok, [%{asset: Assets.from_string("ETH.ETH"), amount: native_balance} | assets_balance]}
    end
  end
end
