defmodule RujiraWeb.Schema.RujiraTypes do
  @moduledoc """
  Defines core GraphQL types for the Rujira API.

  This module contains the root type definitions and field resolvers
  for the Rujira API, including top-level queries and shared types.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias RujiraWeb.Resolvers

  @desc """
  Entry point for accessing all Rujira product data.

  This object groups together all supported products offered by Rujira,
  including Bow, Merge, FIN, Staking, Ventures, Bank, and more.
  """
  object :rujira do
    @desc "Returns all Bow pools available for Rujira Bow"
    field :bow, non_null(list_of(non_null(:bow_pool))) do
      resolve(&Resolvers.Bow.resolver/3)
    end

    @desc "Returns all Merge pools created for Rujira Merge"
    field :merge, non_null(list_of(non_null(:merge_pool))) do
      resolve(&Resolvers.Merge.resolver/3)
    end

    @desc "Returns all trading pairs managed by Rujira Trade"
    field :fin, non_null(list_of(non_null(:fin_pair))) do
      resolve(&Resolvers.Fin.resolver/3)
    end

    @desc "Returns all staking data for Rujira Staking"
    field :staking, non_null(:staking) do
      resolve(&Resolvers.Staking.resolver/3)
    end

    @desc "Returns all venture products data for Rujira Ventures"
    field :ventures, non_null(:ventures) do
      resolve(&Resolvers.Ventures.resolver/3)
    end

    @desc "Shows current supply and bank module data for Rujira tokens"
    field :bank, non_null(:bank) do
      resolve(&Resolvers.Bank.resolver/3)
    end

    @desc "Provides analytics, performance metrics, and aggregated insights"
    field :analytics, non_null(:analytics) do
      resolve(fn _, _, _ -> {:ok, %{}} end)
    end

    @desc "Returns all available leagues data for Rujira League"
    field :league, non_null(list_of(non_null(:league))) do
      resolve(&Resolvers.Leagues.resolver/3)
    end

    @desc "Connection-based access to strategies available in Rujira"
    connection field :strategies, node_type: :strategy, non_null: true do
      arg(:typenames, list_of(non_null(:string)))
      arg(:query, :string)
      resolve(&Resolvers.Strategy.list/3)
    end

    @desc "Retrieves all index vaults deployed through Rujira Index"
    field :index, non_null(list_of(non_null(:index_vault))) do
      resolve(&Resolvers.Index.resolver/3)
    end
  end
end
