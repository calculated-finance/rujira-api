defmodule RujiraWeb.Schema.RujiraTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias RujiraWeb.Resolvers

  @desc "A rujira represents data about rujira products"
  object :rujira do
    field :bow, non_null(list_of(non_null(:bow_pool))) do
      resolve(&Resolvers.Bow.resolver/3)
    end

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

    field :league, non_null(list_of(non_null(:league))) do
      resolve(&Resolvers.Leagues.resolver/3)
    end

    connection field :strategies, node_type: :strategy, non_null: true do
      arg(:typenames, list_of(non_null(:string)))
      arg(:query, :string)
      resolve(&Resolvers.Strategy.list/3)
    end

    field :index, non_null(list_of(non_null(:index_vault))) do
      resolve(&Resolvers.Index.resolver/3)
    end
  end
end
