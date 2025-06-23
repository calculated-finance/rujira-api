defmodule RujiraWeb.Fragments.LeagueFragments do
  @moduledoc false

  @league_stats_fragment """
  fragment LeagueStatsFragment on LeagueStats {
    totalPoints
    participants
  }
  """

  @league_leaderboard_entry_fragment """
  fragment LeagueLeaderboardEntryFragment on LeagueLeaderboardEntry {
    rank
    address
    points
    totalTx
    rankPrevious
    badges
  }
  """

  @league_fragment """
  fragment LeagueFragment on League {
    league
    season
    stats {
      ...LeagueStatsFragment
    }
  }
  #{@league_stats_fragment}
  """

  @league_tx_fragment """
  fragment LeagueTxFragment on LeagueTx {
    height
    txHash
    timestamp
    points
    category
  }
  """

  @league_account_fragment """
  fragment LeagueAccountFragment on LeagueAccount {
    id
    league
    season
    address
    points
    totalTx
    badges
    rank
    rankPrevious
    transactions(first: 10) {
      edges {
        node {
          ...LeagueTxFragment
        }
      }
    }
  }
  #{@league_tx_fragment}
  """

  @league_stats_fragment """
  fragment LeagueStatsFragment on LeagueStats {
    totalPoints
    participants
  }
  """

  @league_leaderboard_entry_fragment """
  fragment LeagueLeaderboardEntryFragment on LeagueLeaderboardEntry {
    rank
    address
    points
    totalTx
    rankPrevious
    badges
  }
  """

  @league_fragment """
  fragment LeagueFragment on League {
    league
    season
    stats {
      ...LeagueStatsFragment
    }
  }
  #{@league_stats_fragment}
  """

  @league_tx_fragment """
  fragment LeagueTxFragment on LeagueTx {
    height
    txHash
    timestamp
    points
    category
  }
  """

  @league_account_fragment """
  fragment LeagueAccountFragment on LeagueAccount {
    id
    league
    season
    address
    points
    totalTx
    badges
    rank
    rankPrevious
    transactions(first: 10) {
      edges {
        node {
          ...LeagueTxFragment
        }
      }
    }
  }
  #{@league_tx_fragment}
  """

  def get_league_stats_fragment, do: @league_stats_fragment
  def get_league_leaderboard_entry_fragment, do: @league_leaderboard_entry_fragment
  def get_league_fragment, do: @league_fragment
  def get_league_tx_fragment, do: @league_tx_fragment
  def get_league_account_fragment, do: @league_account_fragment
end
