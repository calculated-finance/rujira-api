defmodule RujiraWeb.Schema.LeagueTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.LeagueFragments
  import Rujira.Fixtures.League

  @query """
  query {
    league {
      ...LeagueFragment
    }
  }
  #{get_league_fragment()}
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
  #{get_league_account_fragment()}
  """

  test "league account populated", %{conn: conn, account_populated: populated_account} do
    load_league()

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => Base.encode64("LeagueAccount:genesis/0/#{populated_account}")}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  test "league account empty", %{conn: conn, account_empty: empty_account} do
    load_league()

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => Base.encode64("LeagueAccount:genesis/0/#{empty_account}")}
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
  #{get_league_leaderboard_entry_fragment()}
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
