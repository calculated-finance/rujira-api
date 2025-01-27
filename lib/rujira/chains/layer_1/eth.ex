defmodule Rujira.Chains.Layer1.Eth do
  defstruct rpc: "https://ethereum-rpc.publicnode.com"
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Eth do
  def balances(a, address, assets) do
    with {_native_asset, other_assets} <- Enum.split_with(assets, &(&1 == "ETH.ETH")),
         {:ok, native_balance} <-
           Rujira.Chains.Layer1.Evm.native_balance(a.rpc, address, "ETH.ETH"),
         {:ok, assets_balance} <-
           Rujira.Chains.Layer1.Evm.balances_of(a.rpc, address, other_assets) do
      {:ok, native_balance |> Enum.concat(assets_balance)}
    end
  end
end
