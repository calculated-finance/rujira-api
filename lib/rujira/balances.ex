defmodule Rujira.Balances do
  alias Rujira.Chains.Adapter

  @doc """
  Fetches the balances of THORChain supported assets on native chains, with the correct Asset string for THORChain usage
  """
  @spec balances(atom(), String.t()) ::
          {:ok, list(%{asset: String.t(), amount: String.t()})} | {:error, any()}
  def balances(chain, address) do
    with {:ok, adapter} <- Rujira.Chains.get_native_adapter(chain),
         assets <- Rujira.Assets.erc20(chain) do
      Adapter.balances(adapter, address, assets)
    end
  end
end
