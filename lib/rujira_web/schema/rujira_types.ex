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

    field :staking, non_null(:staking) do
      resolve(&Resolvers.Staking.resolver/3)
    end

    field :ventures, non_null(:ventures) do
      resolve(&Resolvers.Ventures.resolver/3)
    end

    field :bank, non_null(:bank) do
      resolve(&Resolvers.Bank.resolver/3)
    end

    field :analytics, non_null(:analytics) do
      resolve(fn _, _, _ -> {:ok, %{}} end)
    end
  end
end
