defmodule Rujira.Balances do
  alias Rujira.Chains.Layer1.Adapter

  alias Thorchain.Types.QueryPoolsResponse
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.Query.Stub, as: Q

  @doc """
  Fetches the balances of Cosmos SDK x/bank tokens.

  The response diff between this and native_balances is "asset" -> "denom"
  """
  @spec cosmos_balances(atom(), String.t()) ::
          {:ok, list(%{denom: String.t(), amount: String.t()})} | {:error, any()}
  def cosmos_balances(:thor, _), do: {:ok, []}
  def cosmos_balances(:kuji, address), do: Rujira.Chains.Cosmos.Kujira.balances(address)

  @doc """
  Fetches the balances of THORChain supported assets on native chains, with the correct Asset string for THORChain usage
  """
  @spec native_balances(atom(), String.t()) ::
          {:ok, list(%{asset: String.t(), amount: String.t()})} | {:error, any()}
  def native_balances(chain, address) do
    with {:ok, adapter} <- Rujira.Chains.get_native_adapter(chain),
         assets <- Rujira.Assets.by_chain(chain) do
      Adapter.balances(adapter, address, assets)
    end
  end
end
