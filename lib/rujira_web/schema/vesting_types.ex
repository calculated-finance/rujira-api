defmodule RujiraWeb.Schema.VestingTypes do
  @moduledoc """
  Defines GraphQL types for Vesting data in the Rujira API.

  This module contains the type definitions and field resolvers for Vesting
  GraphQL objects, including different types of investment strategies.
  """
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Rujira.Assets
  alias Rujira.Contracts
  alias RujiraWeb.Resolvers.Vestings

  node object(:vesting_account) do
    field :address, non_null(:address)
    field :vestings, non_null(list_of(non_null(:vesting)))

    field :value_usd, non_null(:bigint) do
      resolve(fn %{vestings: vestings}, _, _ ->
        {:ok, Vestings.value_usd(vestings)}
      end)
    end
  end

  connection(node_type: :vesting_account)

  node object(:vesting) do
    field :address, non_null(:address)

    field :contract, :contract_info do
      resolve(fn %{address: address}, _, _ ->
        Contracts.info(address)
      end)
    end

    field :creator, non_null(:address)
    field :recipient, non_null(:address)
    field :start_time, non_null(:timestamp)

    field :vested, non_null(:vesting_vested_type)

    field :total, non_null(:balance) do
      resolve(fn %{denom: denom, total: total}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(denom) do
          {:ok, %{amount: total, asset: asset}}
        end
      end)
    end

    field :claimed, non_null(:balance) do
      resolve(fn %{denom: denom, claimed: claimed}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(denom) do
          {:ok, %{amount: claimed, asset: asset}}
        end
      end)
    end

    field :slashed, non_null(:balance) do
      resolve(fn %{denom: denom, slashed: slashed}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(denom) do
          {:ok, %{amount: slashed, asset: asset}}
        end
      end)
    end

    field :remaining, non_null(:balance) do
      resolve(fn %{denom: denom, remaining: remaining}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(denom) do
          {:ok, %{amount: remaining, asset: asset}}
        end
      end)
    end

    field :status, non_null(:string)
    field :title, non_null(:string)
    field :description, non_null(:string)
  end

  connection(node_type: :vesting)

  union :vesting_vested_type do
    types([:vesting_vested_type_saturating_linear])

    resolve_type(fn
      %{type: :saturating_linear}, _ -> :vesting_vested_type_saturating_linear
    end)
  end

  object :vesting_vested_type_saturating_linear do
    field :type, non_null(:string)
    field :max_x, non_null(:bigint)
    field :max_y, non_null(:bigint)
    field :min_x, non_null(:bigint)
    field :min_y, non_null(:bigint)
  end
end
