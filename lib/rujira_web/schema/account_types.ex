defmodule RujiraWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation
  alias RujiraWeb.Resolvers
  import_types(RujiraWeb.Schema.BalanceTypes)

  @desc "A layer_1_account represents data about this address on the layer 1 specified"
  object :layer_1_account do
    interface(:node)
    field :id, non_null(:id)

    field :address, non_null(:address)
    field :chain, non_null(:chain)

    field :balances, non_null(list_of(non_null(:layer_1_balance))) do
      arg(:tokens, list_of(:string))
      @desc "A list of contract addresses for ERC-20, SPL etc token balances"
      resolve(&Resolvers.Balance.native/3)
    end

    field :account, :account do
      resolve(&Resolvers.Account.resolver/3)
    end
  end

  @desc "An account represents data about this address on THORChain and the Rujira app layer, using the mapped address from the root account when required"
  object :account do
    interface(:node)
    field :id, non_null(:id)

    @desc "The THORChain address for this account on the app layer"
    field :address, non_null(:address)

    field :balances, non_null(list_of(non_null(:balance))) do
      resolve(&Resolvers.Balance.cosmos/3)
    end
  end
end
