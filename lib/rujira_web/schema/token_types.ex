defmodule RujiraWeb.Schema.TokenTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:asset) do
    field :asset, non_null(:asset_string)
    field :type, non_null(:asset_type)
    field :chain, non_null(:chain)
    field :metadata, non_null(:metadata), resolve: &RujiraWeb.Resolvers.Token.metadata/3
    field :price, :price, resolve: &RujiraWeb.Resolvers.Token.price/3

    @desc "Explicit Layer 1 and Secured variants of a Layer 1 asset"
    field :variants, :asset_variants
  end

  node object(:denom) do
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

  object :asset_variants do
    field :layer1, non_null(:asset), resolve: &RujiraWeb.Resolvers.Token.layer1/3
    field :secured, non_null(:asset), resolve: &RujiraWeb.Resolvers.Token.secured/3
  end

  enum :asset_type do
    value(:layer_1)
    value(:secured)
    value(:native)
  end
end
