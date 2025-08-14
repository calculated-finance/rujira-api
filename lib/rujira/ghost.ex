defmodule Rujira.Ghost do
  @moduledoc """
  Rujira Ghost - Interfaces for the Ghost borrow, lend & credit protocol
  """
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Ghost.Vault

  def vault_from_id(id) do
    case Deployments.list_targets(Vault)
         |> Enum.find(&(&1.address == id)) do
      nil -> {:error, :not_found}
      target -> Vault.from_target(target)
    end
  end

  def list_vaults do
    Vault
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_async_while_ok(&Vault.from_target/1)
  end

  def load_vault(%Vault{address: address} = vault) do
    with {:ok, status} <- query_vault_status(address),
         {:ok, status} <- Vault.Status.from_query(status) do
      {:ok, %{vault | status: status}}
    end
  end

  # TODO: Memoize & invalidate
  defp query_vault_status(address) do
    Contracts.query_state_smart(address, %{status: %{}})
  end
end
