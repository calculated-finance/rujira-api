defmodule RujiraWeb.Schema.ChainTypes do
  use Absinthe.Schema.Notation

  @desc "A root account represents a single address. This can have multiple layer 1 accounts based on the type of address"
  enum :chain do
    value(:avax)
    value(:base)
    value(:btc)
    value(:bch)
    value(:bsc)
    value(:doge)
    value(:eth)
    value(:gaia)
    value(:kuji)
    value(:ltc)
    value(:noble)
    value(:thor)
    value(:xrp)
  end
end
