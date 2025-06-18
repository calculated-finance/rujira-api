defmodule RujiraWeb.Schema.GhostTypes do
  alias Rujira.Ghost.Registry
  alias Rujira.Contracts
  alias Rujira.Assets
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

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

    field :status, non_null(:ghost_vault_status)
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
end
