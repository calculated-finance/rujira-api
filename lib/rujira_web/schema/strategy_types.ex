defmodule RujiraWeb.Schema.StrategyTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Rujira.Bow

  union :strategy do
    types([:bow_pool_xyk, :thorchain_pool])

    resolve_type(fn
      %Bow.Xyk{}, _ -> :bow_pool_xyk
      %Thorchain.Types.QueryPoolResponse{}, _ -> :thorchain_pool
    end)
  end

  connection(node_type: :strategy)
end
