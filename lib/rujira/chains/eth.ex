defmodule Rujira.Chains.Eth do
  defstruct rpc: "https://ethereum-rpc.publicnode.com"
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Eth do
  def balances(a, address, assets) do
    with {_native_asset, other_assets} <- Enum.split_with(assets, &(&1 == "ETH.ETH")),
         {:ok, native_balance} <-
           Rujira.Chains.Evm.native_balance(a.rpc, address, "ETH.ETH"),
         {:ok, assets_balance} <-
           Rujira.Chains.Evm.balances_of(a.rpc, address, other_assets) do
      {:ok, native_balance |> Enum.concat(assets_balance)}
    end
  end
end
