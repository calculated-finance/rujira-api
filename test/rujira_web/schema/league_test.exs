defmodule RujiraWeb.Schema.LeagueTest do
  use RujiraWeb.ConnCase

  import Rujira.Fixtures.League

  @accounts Application.compile_env(:rujira, :accounts)

  @empty_account Keyword.fetch!(@accounts, :empty_account)
  @populated_account Keyword.fetch!(@accounts, :populated_account)

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

  @query """
  query {
    league {
      ...LeagueFragment
    }
  }
  #{@league_fragment}
  """

  test "leagues", %{conn: conn} do
    load_league()

    conn = post(conn, "/api", %{"query" => @query})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on LeagueAccount {
        ...LeagueAccountFragment
      }
    }
  }
  #{@league_account_fragment}
  """

  test "league account populated", %{conn: conn} do
    load_league()

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => Base.encode64("LeagueAccount:genesis/0/#{@populated_account}")}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  test "league account empty", %{conn: conn} do
    load_league()

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => Base.encode64("LeagueAccount:genesis/0/#{@empty_account}")}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($sort_by: LeagueLeaderboardSortBy!, $sort_dir: LeagueLeaderboardSortDir!, $first: Int!) {
    league {
      league
      season
      leaderboard(sortBy: $sort_by, sortDir: $sort_dir, first: $first) {
        edges {
          node {
            ...LeagueLeaderboardEntryFragment
          }
        }
      }
    }
  }
  #{@league_leaderboard_entry_fragment}
  """

  test "league leaderboard", %{conn: conn} do
    load_league()

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"sort_by" => "POINTS", "sort_dir" => "DESC", "first" => 10}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end
end
