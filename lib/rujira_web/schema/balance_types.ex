defmodule RujiraWeb.Schema.BalanceTypes do
  use Absinthe.Schema.Notation

  @desc "The balance of a token or coin on a layer 1 chain"
  object :layer_1_balance do
    field :asset, non_null(:asset)
    field :amount, non_null(:bigint)
  end

  @desc "Relacement for layer_1_balance"
  object :balance do
    field :asset, non_null(:asset)
    field :amount, non_null(:bigint)
  end
end
