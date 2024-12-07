defmodule RujiraWeb.Schema.RujiraTypes do
  use Absinthe.Schema.Notation
  alias RujiraWeb.Resolvers

  @desc "A rujira represents data about rujira products"
  object :rujira do

    field :merge, list_of(:merge_pool) do
      resolve(&Resolvers.Merge.merge_stats/3)
    end
  end
end
