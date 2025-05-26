defmodule RujiraWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias RujiraWeb.Resolvers

  @desc "A layer_1_account represents data about this address on the layer 1 specified"
  node object(:layer_1_account) do
    field :address, non_null(:address)
    field :chain, non_null(:chain)

    field :balances, list_of(non_null(:layer_1_balance)) do
      @desc "A list of contract addresses for ERC-20, SPL etc token balances"
      resolve(&Resolvers.Balance.resolver/3)
    end

    field :account, :account do
      resolve(&Resolvers.Account.resolver/3)
    end

    field :liquidity_accounts, non_null(list_of(non_null(:thorchain_liquidity_provider))) do
      resolve(&Resolvers.Thorchain.liquidity_accounts/3)
    end
  end

  @desc "An account represents data about this address on THORChain and the Rujira app layer, using the mapped address from the root account when required"
  node object(:account) do
    @desc "The THORChain address for this account on the app layer"
    field :address, non_null(:address)

    field :merge, :merge_stats do
      resolve(&Resolvers.Merge.account/3)
    end

    field :bow, non_null(list_of(non_null(:bow_account))) do
      resolve(&Resolvers.Bow.accounts/3)
    end

    field :fin, :fin_account do
      resolve(&Resolvers.Fin.account/3)
    end

    field :pilot, :pilot_account do
      resolve(&Resolvers.Pilot.account/3)
    end

    field :staking, non_null(:staking_accounts) do
      resolve(&Resolvers.Staking.accounts/3)
    end
  end
end
