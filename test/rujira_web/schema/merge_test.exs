defmodule RujiraWeb.Schema.MergeTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.MergeFragments

  @accounts Application.compile_env(:rujira, :accounts)
  @config Application.compile_env(:rujira, __MODULE__)

  @empty_account Keyword.fetch!(@accounts, :empty_account)
  @populated_account Keyword.fetch!(@accounts, :populated_account)

  @merge_pool Keyword.fetch!(@config, :merge_pool)

  @query """
  query {
    merge {
      ...MergePoolFragment
    }
  }
  #{get_merge_pool_fragment()}
  """

  test "merge pools", %{conn: conn} do
    conn = post(conn, "/api", %{"query" => @query})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on MergePool {
        ...MergePoolFragment
      }
    }
  }
  #{get_merge_pool_fragment()}
  """

  test "merge pool", %{conn: conn} do
    encoded_id =
      Base.encode64("MergePool:#{@merge_pool}")

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => encoded_id}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on MergeAccount {
        ...MergeAccountFragment
      }
    }
  }
  #{get_merge_account_fragment()}
  """
  test "merge account empty", %{conn: conn} do
    encoded_id =
      Base.encode64("MergeAccount:#{@merge_pool}/#{@empty_account}")

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => encoded_id}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  test "merge account populated", %{conn: conn} do
    encoded_id =
      Base.encode64("MergeAccount:#{@merge_pool}/#{@populated_account}")

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => encoded_id}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on Layer1Account {
        id
        account {
          merge {
            ...MergeStatsFragment
          }
        }
      }
    }
  }
  #{get_merge_stats_fragment()}
  """

  test "merge stats", %{conn: conn} do
    encoded_id =
      Base.encode64("Layer1Account:thor:sthor1t4gsjfs8q8j3mw2e402r8vzrtaslsf5re3ktut")

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => encoded_id}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end
end
