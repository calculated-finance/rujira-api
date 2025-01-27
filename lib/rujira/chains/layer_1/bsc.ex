defmodule Rujira.Chains.Layer1.Bsc do
  defstruct rpc: "https://bnb.api.onfinality.io/public"
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Bsc do
  def balances(a, address, assets) do
    with {_native_asset, other_assets} <- Enum.split_with(assets, &(&1 == "BSC.BNB")),
         {:ok, native_balance} <-
           Rujira.Chains.Layer1.Evm.native_balance(a.rpc, address, "BSC.BNB"),
         {:ok, assets_balance} <-
           Rujira.Chains.Layer1.Evm.balances_of(a.rpc, address, other_assets) do
      {:ok, native_balance |> Enum.concat(assets_balance)}
    end
  end
end
