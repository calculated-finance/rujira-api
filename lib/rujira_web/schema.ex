defmodule RujiraWeb.Schema do
  use Absinthe.Schema
  import_types(RujiraWeb.Schema.ChainTypes)

  query do
    @desc "Start with a list of chains"
    field :chains, non_null(:chains) do
      resolve(&RujiraWeb.Resolvers.Chains.resolver/3)
    end
  end
end
