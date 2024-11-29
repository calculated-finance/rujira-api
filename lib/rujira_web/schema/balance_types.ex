defmodule RujiraWeb.Schema.BalanceTypes do
  use Absinthe.Schema.Notation

  @desc "The balance of a token or coin on a layer 1 chain"
  object :layer_1_balance do
    field :asset, non_null(:string)
    field :amount, non_null(:bigint)
    field :metadata, non_null(:metadata), resolve: &RujiraWeb.Resolvers.Balance.metadata/3
    field :price, :price, resolve: &RujiraWeb.Resolvers.Balance.price/3
  end

  @desc "The balance of a token or coin on the app layer"
  object :balance do
    field :denom, non_null(:string)
    field :amount, non_null(:bigint)
    field :metadata, non_null(:metadata), resolve: &RujiraWeb.Resolvers.Balance.metadata/3
    field :price, :price, resolve: &RujiraWeb.Resolvers.Balance.price/3
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
