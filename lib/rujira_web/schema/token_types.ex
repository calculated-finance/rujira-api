defmodule RujiraWeb.Schema.TokenTypes do
  use Absinthe.Schema.Notation

  object :layer_1_asset do
    field :asset, non_null(:string)
    field :metadata, non_null(:metadata), resolve: &RujiraWeb.Resolvers.Token.metadata/3
    field :price, :price, resolve: &RujiraWeb.Resolvers.Token.price/3
  end

  object :denom do
    field :denom, non_null(:string)
    field :metadata, non_null(:metadata), resolve: &RujiraWeb.Resolvers.Token.metadata/3
    field :price, :price, resolve: &RujiraWeb.Resolvers.Token.price/3
  end

  @desc "Metadata for a token"
  object :metadata do
    field :symbol, non_null(:string)
    field :decimals, non_null(:integer)
  end

  @desc "Price data for a token"
  object :price do
    @desc "Current price, 12 decimal places"
    field :current, :bigint
    field :change_day, :float
  end
end
