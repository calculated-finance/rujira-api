defmodule Rujira.Ghost do
  @moduledoc """
  Rujira Ghost - Interfaces for the Ghost borrow, lend & credit protocol
  """
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Ghost.Registry
  alias Rujira.Ghost.Vault

  def vault_from_id(id) do
    Contracts.get({Vault, id})
  end

  def list_vaults do
    Deployments.list_targets(Vault)
    |> Task.async_stream(&get_vault/1, timeout: 30_000)
    |> Enum.reduce({:ok, []}, fn
      {:ok, {:ok, x}}, {:ok, xs} ->
        {:ok, [x | xs]}

      _, err ->
        err
    end)
  end

  def load_vault(%Vault{address: address} = vault) do
    with {:ok, status} <- query_vault_status(address),
         {:ok, status} <- Vault.Status.from_query(status) do
      {:ok, %{vault | status: status}}
    end
  end

  def load_vault(%{address: address}) do
    with {:ok, vault} <- get_vault(%{address: address}) do
      load_vault(vault)
    end
  end

  # TODO: Memoize & invalidate
  defp query_vault_status(address) do
    Contracts.query_state_smart(address, %{status: %{}})
  end

  def get_vault(%{address: address}) do
    Contracts.get({Vault, address})
  end
end
