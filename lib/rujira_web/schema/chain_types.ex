defmodule RujiraWeb.Schema.ChainTypes do
  use Absinthe.Schema.Notation
  alias RujiraWeb.Resolvers
  import_types(RujiraWeb.Schema.AccountTypes)

  @desc "A root account represents a single address. This can have multiple layer 1 accounts based on the type of address"
  object :chains do
    field :avax, :chain
    field :btc, :chain
    field :bch, :chain
    field :bsc, :chain
    field :doge, :chain
    field :eth, :chain
    field :gaia, :chain
    field :kuji, :chain
    field :ltc, :chain
    field :thor, :chain
  end

  object :chain do
    field :accounts, list_of(:native_account) do
      arg(:addresses, list_of(:string))
      resolve(&Resolvers.Account.resolver/3)
    end
  end
end
