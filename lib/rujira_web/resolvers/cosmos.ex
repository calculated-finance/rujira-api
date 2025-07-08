defmodule RujiraWeb.Resolvers.Cosmos do
  @moduledoc """
  Handles GraphQL resolution for Cosmos-related queries.
  """
  def staking(%{chain: chain, address: address}, _, _) do
    with {:ok, module} <- Rujira.Chains.get_native_adapter(chain) do
      module.get_delegations(address)
    end
  end

  def unbonding(%{chain: chain, address: address}, _, _) do
    with {:ok, module} <- Rujira.Chains.get_native_adapter(chain) do
      module.get_unbonding_delegations(address)
    end
  end

  def vesting_account(%{chain: chain, address: address}, _, _) do
    with {:ok, module} <- Rujira.Chains.get_native_adapter(chain) do
      module.get_vesting_account(address)
    end
  end
end
