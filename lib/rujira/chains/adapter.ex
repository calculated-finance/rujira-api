defprotocol Rujira.Chains.Adapter do
  alias Rujira.Assets.Asset

  @spec balances(t, String.t(), list()) ::
          {:ok, list(%{asset: Asset.t(), amount: non_neg_integer()})} | {:error, any()}
  def balances(adapter, address, assets)
end
