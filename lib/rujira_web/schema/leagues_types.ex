defmodule RujiraWeb.Schema.LeaguesTypes do
  @moduledoc """
  Defines GraphQL types for Leagues data in the Rujira API.

  This module contains the type definitions and field resolvers for Leagues
  GraphQL objects, including leaderboards, statistics, and user rankings.
  """

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
      arg(:search, :string)
      arg(:sort_by, non_null(:league_leaderboard_sort_by))
      arg(:sort_dir, non_null(:league_leaderboard_sort_dir))
      resolve(&Resolvers.Leagues.leaderboard/3)
    end
  end

  connection(node_type: :league_leaderboard_entry)

  object :league_leaderboard_entry do
    field :rank, non_null(:integer)
    field :address, non_null(:address)
    field :points, non_null(:bigint)
    field :total_tx, non_null(:integer)
    @desc "Rank from 7 days ago"
    field :rank_previous, :integer
    field :badges, list_of(non_null(:string))
  end

  object :league_stats do
    field :total_points, non_null(:bigint)
    field :participants, non_null(:integer)
  end

  node object(:league_account) do
    field :league, non_null(:string)
    field :season, non_null(:integer)
    field :address, non_null(:address)
    field :points, non_null(:bigint)
    field :total_tx, non_null(:integer)
    field :badges, list_of(non_null(:string))
    field :rank, :integer
    field :rank_previous, :integer

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
    value(:rank_previous)
  end

  enum :league_leaderboard_sort_dir do
    value(:asc)
    value(:desc)
  end
end
