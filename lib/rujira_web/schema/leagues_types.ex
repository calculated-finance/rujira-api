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
      resolve(&Resolvers.Leagues.leaderboard/3)
    end
  end

  connection(node_type: :league_leaderboard_entry)

  object :league_leaderboard_entry do
    field :rank, non_null(:integer)
    field :address, non_null(:string)
    field :points, non_null(:bigint)
    field :total_tx, non_null(:integer)
    field :rank_change, :integer
    field :badges, list_of(non_null(:string))
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
end
