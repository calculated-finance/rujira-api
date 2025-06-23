defmodule RujiraWeb.Schema.GhostTypes do
  @moduledoc """
  Defines GraphQL types for Ghost Protocol-related data in the Rujira API.

  This module contains the type definitions and field resolvers for Ghost Protocol
  GraphQL objects, including vaults, accounts, and related data structures.
  """

  alias Rujira.Assets
  alias Rujira.Contracts
  alias Rujira.Ghost
  alias Rujira.Ghost.Registry
  use Absinthe.Relay.Schema.Notation, :modern
  use Absinthe.Schema.Notation

  node object(:ghost_vault) do
    field :address, non_null(:address)

    field :asset, non_null(:asset) do
      resolve(fn %{denom: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    field :interest, non_null(:ghost_vault_interest)

    field :registry, non_null(:ghost_registry) do
      resolve(fn %{registry: address}, _, _ ->
        Contracts.get({Registry, address})
      end)
    end

    field :status, non_null(:ghost_vault_status) do
      resolve(fn vault, _, _ ->
        with {:ok, %{status: status}} <- Ghost.load_vault(vault) do
          {:ok, status}
        end
      end)
    end
  end

  object :ghost_vault_interest do
    field :target_utilization, non_null(:bigint)
    field :base_rate, non_null(:bigint)
    field :step1, non_null(:bigint)
    field :step2, non_null(:bigint)
  end

  node object(:ghost_registry) do
    field :code_id, non_null(:integer)
    field :checksum, non_null(:string)
  end

  object :ghost_vault_status do
    field :last_updated, non_null(:timestamp)
    field :utilization_ratio, non_null(:bigint)
    field :debt_rate, non_null(:bigint)
    field :lend_rate, non_null(:bigint)
    field :debt_pool, non_null(:ghost_vault_pool)
    field :deposit_pool, non_null(:ghost_vault_pool)
  end

  object :ghost_vault_pool do
    field :size, non_null(:bigint)
    field :shares, non_null(:bigint)
    field :ratio, non_null(:bigint)
  end

  object :ghost_vault_account do
    field :account, non_null(:address)
    field :vault, non_null(:ghost_vault)

    field :shares, non_null(:balance) do
      resolve(fn %{shares: shares, vault: %{denom: denom}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(denom) do
          {:ok, %{amount: shares, asset: asset}}
        end
      end)
    end

    field :value, non_null(list_of(non_null(:balance))) do
      resolve(fn %{value: value}, _, _ ->
        Rujira.Enum.reduce_while_ok(value, [], fn %{amount: amount, denom: denom} ->
          with {:ok, asset} <- Assets.from_denom(denom) do
            {:ok, %{amount: amount, asset: asset}}
          end
        end)
      end)
    end

    field :value_usd, non_null(:bigint) do
      resolve(fn %{value: value}, _, _ ->
        {:ok, RujiraWeb.Resolvers.Bow.value_usd(value)}
      end)
    end
  end
end
