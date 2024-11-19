defmodule RujiraWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation
  alias RujiraWeb.Resolvers
  import_types(RujiraWeb.Schema.BalanceTypes)

  @desc "A root account represents a single address. This can have multiple layer 1 accounts based on the type of address"
  object :root_account do
    field :address, :string
    field :account, :account, do: resolve(&Resolvers.Account.resolver/3)

    field :avax, :l1_account, do: resolve(&Resolvers.Account.avax_resolver/3)
    field :btc, :l1_account, do: resolve(&Resolvers.Account.btc_resolver/3)
    field :bch, :l1_account, do: resolve(&Resolvers.Account.bch_resolver/3)
    field :bsc, :l1_account, do: resolve(&Resolvers.Account.bsc_resolver/3)
    field :doge, :l1_account, do: resolve(&Resolvers.Account.doge_resolver/3)
    field :eth, :l1_account, do: resolve(&Resolvers.Account.eth_resolver/3)
    field :gaia, :l1_account, do: resolve(&Resolvers.Account.gaia_resolver/3)
    field :kuji, :l1_account, do: resolve(&Resolvers.Account.kuji_resolver/3)
    field :ltc, :l1_account, do: resolve(&Resolvers.Account.ltc_resolver/3)
    field :thor, :l1_account, do: resolve(&Resolvers.Account.thor_resolver/3)
  end

  @desc "A l1_account represents data about this address on the layer 1 specified"
  object :l1_account do
    field :balance, :l1_balance
  end

  @desc "An account represents data about this address on the Rujira app layer, using the mapped address from the root account when required"
  object :account do
    @desc "The THORChain address for this account on the app layer"
    field :address, :string
    field :balances, list_of(:balance)
  end
end
