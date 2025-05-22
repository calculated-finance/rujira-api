defmodule RujiraWeb.Schema.LeaguesTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias RujiraWeb.Resolvers

  object :league do
    field :league, non_null(:string)
    field :season, non_null(:integer)
    field :stats, non_null(:league_stats) do
      resolve(&Resolvers.Leagues.stats/3)
    end
    connection field :leaderboard, node_type: :league_leaderboard_entry do
      arg :search, :string
      arg :sort_by, :league_leaderboard_sort_by
      arg :sort_dir, :league_leaderboard_sort_dir
      resolve(&Resolvers.Leagues.leaderboard/3)
    end
    field :badges, non_null(list_of(:league_badge)) do
      resolve(&Resolvers.Leagues.badges/3)
    end
  end

  connection(node_type: :league_leaderboard_entry)

  object :league_leaderboard_entry do
    field :rank, non_null(:integer)
    field :address, non_null(:string)
    field :points, non_null(:bigint)
    field :total_tx, non_null(:integer)
    field :rank_change, :integer
  end

  object :league_badge do
    field :address, non_null(:string)
    field :badges, non_null(list_of(:string))
  end

  object :league_stats do
    field :total_points, non_null(:bigint)
    field :participants, non_null(:integer)
  end

  node object(:league_account) do
    field :league, non_null(:string)
    field :season, non_null(:integer)
    field :address, non_null(:string)
    field :points, non_null(:bigint)
    field :total_tx, non_null(:integer)
    field :rank_change, :integer
    field :rank, non_null(:integer)
    connection field :transactions, node_type: :league_tx do
      resolve(&Resolvers.Leagues.account_txs/3)
    end
  end

  connection(node_type: :league_tx)

  object :league_tx do
    field :height, non_null(:integer)
    field :tx_hash, non_null(:string)
    field :timestamp, non_null(:timestamp)
    field :points, non_null(:bigint)
    field :category, non_null(:string)
  end

  enum :league_leaderboard_sort_by do
    value(:points)
    value(:total_tx)
    value(:rank)
    value(:rank_change)
  end

  enum :league_leaderboard_sort_dir do
    value(:asc)
    value(:desc)
  end
end
