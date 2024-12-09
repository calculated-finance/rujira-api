defmodule RujiraWeb.Schema.BalanceTypes do
  use Absinthe.Schema.Notation

  @desc "The balance of a token or coin on a layer 1 chain"
  object :layer_1_balance do
    field :asset, non_null(:asset), resolve: &RujiraWeb.Resolvers.Token.asset/3
    field :amount, non_null(:bigint)
  end

  @desc "The balance of a token or coin on the app layer"
  object :balance do
    field :denom, non_null(:denom), resolve: &RujiraWeb.Resolvers.Token.denom/3
    field :amount, non_null(:bigint)
  end
end
