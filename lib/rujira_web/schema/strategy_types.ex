defmodule RujiraWeb.Schema.StrategyTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Rujira.Bow

  union :strategy do
    types([:bow_pool_xyk, :thorchain_pool, :index_vault])

    resolve_type(fn
      %Bow.Xyk{}, _ -> :bow_pool_xyk
      %Thorchain.Types.QueryPoolResponse{}, _ -> :thorchain_pool
      %Rujira.Index.Vault{}, _ -> :index_vault
    end)
  end

  connection(node_type: :strategy)

  union :strategy_account do
    types([:bow_account, :thorchain_liquidity_provider, :index_account])

    resolve_type(fn
      %Bow.Account{}, _ -> :bow_account
      %Thorchain.Types.QueryLiquidityProviderResponse{}, _ -> :thorchain_liquidity_provider
      %Rujira.Index.Account{}, _ -> :index_account
    end)
  end

  connection(node_type: :strategy_account)
end
