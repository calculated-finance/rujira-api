defprotocol Rujira.Chains.Adapter do
  @spec balances(t, String.t(), list()) ::
          {:ok, list(%{asset: String.t(), amount: non_neg_integer()})} | {:error, any()}
  def balances(adapter, address, assets)
end
