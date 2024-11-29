defprotocol Rujira.Chains.Layer1.Adapter do
  @spec balances(t, String.t()) ::
          {:ok, list(%{asset: String.t(), amount: non_neg_integer()})} | {:error, any()}
  def balances(adapter, address)
end
