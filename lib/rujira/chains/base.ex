defmodule Rujira.Chains.Base do
  defstruct rpc: "https://base.api.onfinality.io/public"
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Avax do
  alias Rujira.Assets

  def balances(a, address, assets) do
    with {_native_asset, other_assets} <- Enum.split_with(assets, &(&1 == "BASE.ETH")),
         {:ok, native_balance} <-
           Rujira.Chains.Evm.native_balance(a.rpc, address, Assets.from_string("BASE.ETH")),
         {:ok, assets_balance} <-
           Rujira.Chains.Evm.balances_of(a.rpc, address, other_assets) do
      {:ok, native_balance |> Enum.concat(assets_balance)}
    end
  end
end
