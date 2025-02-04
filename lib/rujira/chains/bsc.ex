defmodule Rujira.Chains.Bsc do
  defstruct rpc: "https://bnb.api.onfinality.io/public"
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Bsc do
  alias Rujira.Assets

  def balances(a, address, assets) do
    with {_native_asset, other_assets} <- Enum.split_with(assets, &(&1 == "BSC.BNB")),
         {:ok, native_balance} <-
           Rujira.Chains.Evm.native_balance(a.rpc, address, Assets.from_string("BSC.BNB")),
         {:ok, assets_balance} <-
           Rujira.Chains.Evm.balances_of(a.rpc, address, other_assets) do
      {:ok, native_balance |> Enum.concat(assets_balance)}
    end
  end
end
