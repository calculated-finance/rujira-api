defmodule RujiraWeb.Schema.ChainTypes do
  use Absinthe.Schema.Notation
  alias RujiraWeb.Resolvers
  import_types(RujiraWeb.Schema.AccountTypes)

  @desc "A root account represents a single address. This can have multiple layer 1 accounts based on the type of address"
  object :chains do
    field :avax, :native_chain
    field :btc, :native_chain
    field :bch, :native_chain
    field :bsc, :native_chain
    field :doge, :native_chain
    field :eth, :native_chain
    field :gaia, :native_chain
    field :kuji, :native_chain
    field :ltc, :native_chain
    field :thor, :thor_chain
  end

  object :native_chain do
    field :accounts, list_of(:native_account) do
      arg(:addresses, list_of(:string))
      resolve(&Resolvers.Account.resolver/3)
    end
  end

  object :thor_chain do
    field :accounts, list_of(:account) do
      arg(:addresses, list_of(:string))
      resolve(&Resolvers.Account.resolver/3)
    end
  end
end
