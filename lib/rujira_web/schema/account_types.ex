defmodule RujiraWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation
  alias RujiraWeb.Resolvers

  @desc "A root account represents a single address. This can have multiple layer 1 accounts based on the type of address"
  object :root_account do
    field :address, :string

    field :avax, :l1_account, do: resolve(&Resolvers.Chain.avax_resolver/3)
    field :btc, :l1_account, do: resolve(&Resolvers.Chain.btc_resolver/3)
    field :bch, :l1_account, do: resolve(&Resolvers.Chain.bch_resolver/3)
    field :bsc, :l1_account, do: resolve(&Resolvers.Chain.bsc_resolver/3)
    field :doge, :l1_account, do: resolve(&Resolvers.Chain.doge_resolver/3)
    field :eth, :l1_account, do: resolve(&Resolvers.Chain.eth_resolver/3)
    field :gaia, :l1_account, do: resolve(&Resolvers.Chain.gaia_resolver/3)
    field :kuji, :l1_account, do: resolve(&Resolvers.Chain.kuji_resolver/3)
    field :ltc, :l1_account, do: resolve(&Resolvers.Chain.ltc_resolver/3)
    field :thor, :l1_account, do: resolve(&Resolvers.Chain.thor_resolver/3)
  end

  @desc "A l1_account represents data about this address on the layer 1 specified"
  object :l1_account do
    field :balance, :string

    field :account, :account do
      resolve(&Resolvers.Account.account_resolver/3)
    end
  end

  @desc "An account represents data about this address on the Rujira app layer, using the mapped address from the root account"
  object :account do
    field :address, :string
  end
end
