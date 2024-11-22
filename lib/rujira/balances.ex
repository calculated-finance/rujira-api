defmodule Rujira.Balances do
  alias Rujira.Chains.Native.Adapter

  @doc """
  Fetches the balances of Cosmos SDK x/bank tokens.

  The response diff between this and native_balances is "asset" -> "denom"
  """
  @spec cosmos_balances(atom(), String.t()) ::
          {:ok, list(%{denom: String.t(), amount: String.t()})} | {:error, any()}
  def cosmos_balances(:thor, address), do: Rujira.Chains.Cosmos.Thor.balances(address)

  @doc """
  Fetches the balances of THORChain supported assets on native chains, with the correct Asset string for THORChain usage
  """
  @spec native_balances(atom(), String.t()) ::
          {:ok, list(%{asset: String.t(), amount: String.t()})} | {:error, any()}
  def native_balances(chain, address) do
    with {:ok, adapter} <- Rujira.Chains.get_native_adapter(chain) do
      Adapter.balances(adapter, address)
    end
  end
end
