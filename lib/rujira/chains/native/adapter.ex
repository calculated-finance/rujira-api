defprotocol Rujira.Chains.Native.Adapter do
  @spec balances(t, String.t()) ::
          {:ok, list(%{asset: String.t(), amount: String.t()})} | {:error, any()}
  def balances(adapter, address)
end
