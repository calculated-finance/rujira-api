defmodule RujiraWeb.Schema.StrategiesTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:strategies) do
    connection field :strategies, node_type: :strategy, non_null: true do
      arg(:resolution, non_null(:string))
      resolve(&RujiraWeb.Resolvers.Fin.candles/3)
    end
  end
end
