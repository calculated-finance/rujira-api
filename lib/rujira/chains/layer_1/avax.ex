defmodule Rujira.Chains.Layer1.Avax do
  defstruct rpc: "https://api.avax.network/ext/bc/C/rpc"
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Avax do
  def balances(a, address, assets) do
    with {_native_asset, other_assets} <- Enum.split_with(assets, &(&1 == "AVAX.AVAX")),
         {:ok, native_balance} <-
           Rujira.Chains.Layer1.Evm.native_balance(a.rpc, address, "AVAX.AVAX"),
         {:ok, assets_balance} <-
           Rujira.Chains.Layer1.Evm.balances_of(a.rpc, address, other_assets) do
      {:ok, native_balance |> Enum.concat(assets_balance)}
    end
  end
end
