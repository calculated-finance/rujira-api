defmodule RujiraWeb.Schema.ChainTypes do
  use Absinthe.Schema.Notation
  alias RujiraWeb.Resolvers
  import_types(RujiraWeb.Schema.AccountTypes)

  @desc "A root account represents a single address. This can have multiple layer 1 accounts based on the type of address"
  object :chains do
    field :avax, non_null(:chain)
    field :btc, non_null(:chain)
    field :bch, non_null(:chain)
    field :bsc, non_null(:chain)
    field :doge, non_null(:chain)
    field :eth, non_null(:chain)
    field :gaia, non_null(:chain)
    field :kuji, non_null(:chain)
    field :ltc, non_null(:chain)
    field :thor, non_null(:chain)
  end

  object :chain do
    field :accounts, non_null(list_of(non_null(:native_account))) do
      arg(:addresses, non_null(list_of(non_null(:string))))
      resolve(&Resolvers.Account.resolver/3)
    end
  end
end
