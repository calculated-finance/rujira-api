defmodule RujiraWeb.Schema.StrategyTypes do
  @moduledoc """
  Defines GraphQL types for Strategy data in the Rujira API.

  This module contains the type definitions and field resolvers for Strategy
  GraphQL objects, including different types of investment strategies.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Rujira.Bow

  union :strategy do
    types([:bow_pool_xyk, :thorchain_pool, :index_vault, :staking_pool, :perps_pool])

    resolve_type(fn
      %Bow.Xyk{}, _ -> :bow_pool_xyk
      %Thorchain.Types.QueryPoolResponse{}, _ -> :thorchain_pool
      %Rujira.Index.Vault{}, _ -> :index_vault
      %Rujira.Staking.Pool{}, _ -> :staking_pool
      %Rujira.Perps.Pool{}, _ -> :perps_pool
    end)
  end

  connection(node_type: :strategy)

  union :strategy_account do
    types([
      :bow_account,
      :thorchain_liquidity_provider,
      :index_account,
      :staking_account,
      :perps_account
    ])

    resolve_type(fn
      %Bow.Account{}, _ -> :bow_account
      %Thorchain.Types.QueryLiquidityProviderResponse{}, _ -> :thorchain_liquidity_provider
      %Rujira.Index.Account{}, _ -> :index_account
      %Rujira.Staking.Account{}, _ -> :staking_account
      %Rujira.Perps.Account{}, _ -> :perps_account
    end)
  end

  connection(node_type: :strategy_account)

  enum :strategy_sort_by do
    value(:name)
    value(:tvl)
    value(:apr)
  end

  enum :strategy_sort_dir do
    value(:asc)
    value(:desc)
  end
end
