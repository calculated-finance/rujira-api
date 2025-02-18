defmodule RujiraWeb.Schema.RujiraTypes do
  use Absinthe.Schema.Notation
  alias RujiraWeb.Resolvers

  @desc "A rujira represents data about rujira products"
  object :rujira do
    field :merge, non_null(list_of(non_null(:merge_pool))) do
      resolve(&Resolvers.Merge.resolver/3)
    end

    field :fin, non_null(list_of(non_null(:fin_pair))) do
      resolve(&Resolvers.Fin.resolver/3)
    end

    field :staking, non_null(list_of(non_null(:staking_pool))) do
      resolve(&Resolvers.Staking.resolver/3)
    end

    field :tokens, non_null(list_of(non_null(:balance))) do
      resolve(&Resolvers.Bank.total_supply/3)
    end
  end
end
