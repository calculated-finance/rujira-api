defmodule RujiraWeb.Schema.BalanceTypes do
  use Absinthe.Schema.Notation

  @desc "The balance of a token or coin on a layer 1 chain"
  object :l1_balance do
    field :asset, :string
    field :amount, :string
  end

  @desc "The balance of a token or coin on the app layer"
  object :balance do
    field :denom, :string
    field :amount, :string
  end
end
