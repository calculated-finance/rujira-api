defmodule RujiraWeb.Schema.ChainTypes do
  use Absinthe.Schema.Notation
  import_types(RujiraWeb.Schema.AccountTypes)

  @desc "A root account represents a single address. This can have multiple layer 1 accounts based on the type of address"
  enum :chain do
    value(:avax)
    value(:btc)
    value(:bch)
    value(:bsc)
    value(:doge)
    value(:eth)
    value(:gaia)
    value(:kuji)
    value(:ltc)
    value(:thor)
  end
end
