defmodule RujiraWeb.Schema.BalanceTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  @desc "The balance of a token or coin on a layer 1 chain"
  object :layer_1_balance do
    field :asset, non_null(:layer_1_asset), resolve: &RujiraWeb.Resolvers.Token.asset/3
    field :amount, non_null(:bigint)
  end

  node object(:layer_1_asset) do
    field :asset, non_null(:string)
    field :metadata, non_null(:metadata), resolve: &RujiraWeb.Resolvers.Token.metadata/3
    field :price, :price, resolve: &RujiraWeb.Resolvers.Token.price/3
  end

  @desc "The balance of a token or coin on the app layer"
  object :balance do
    field :denom, non_null(:denom), resolve: &RujiraWeb.Resolvers.Token.denom/3
    field :amount, non_null(:bigint)
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
end
