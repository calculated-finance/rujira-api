defmodule Rujira.Ghost do
  alias Rujira.Deployments
  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Registry
  alias Rujira.Contracts

  def registry_from_id(id) do
    Contracts.get({Registry, id})
  end

  def vault_from_id(id) do
    Contracts.get({Vault, id})
  end

  def list_vaults() do
    Deployments.list_targets(Vault)
    |> Task.async_stream(&get_vault/1, timeout: 30_000)
    |> Enum.reduce({:ok, []}, fn
      {:ok, {:ok, x}}, {:ok, xs} ->
        {:ok, [x | xs]}

      _, err ->
        err
    end)
  end

  def get_vault(%{address: address}) do
    Contracts.get({Vault, address})
  end
end
