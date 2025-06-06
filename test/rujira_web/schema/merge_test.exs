defmodule RujiraWeb.Schema.MergeTest do
  use RujiraWeb.ConnCase

  @merge_status_fragment """
  fragment MergeStatusFragment on MergeStatus {
    merged
    shares
    size
    currentRate
    shareValue
    shareValueChange
    apr
  }
  """

  @merge_pool_fragment """
  fragment MergePoolFragment on MergePool {
    id
    address
    contract {
      admin
      label
    }
    mergeAsset {
      asset
    }
    mergeSupply
    rujiAsset {
      asset
    }
    rujiAllocation
    decayStartsAt
    decayEndsAt
    currentRate
    startRate
    status {
      ...MergeStatusFragment
    }
  }
  """

  @merge_account_fragment """
  fragment MergeAccountFragment on MergeAccount {
    id
    pool {
      id
      address
    }
    merged {
      amount
      asset {
        asset
      }
    }
    shares
    size {
      amount
      asset {
        asset
      }
    }
    rate
  }
  """

  @merge_stats_fragment """
  fragment MergeStatsFragment on MergeStats {
    totalSize {
      amount
      asset {
        asset
      }
    }
    accounts {
      ...MergeAccountFragment
    }
  }
  """

  @query """
  query {
    merge {
      ...MergePoolFragment
    }
  }
  #{@merge_status_fragment}
  #{@merge_pool_fragment}
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
  #{@merge_status_fragment}
  #{@merge_pool_fragment}
  """

  test "merge pool", %{conn: conn} do
    encoded_id =
      Base.encode64("MergePool:sthor1nc5tatafv6eyq7llkr2gv50ff9e22mnf70qgjlv737ktmt4eswrqysrzhu")

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
  #{@merge_account_fragment}
  """

  test "merge account", %{conn: conn} do
    encoded_id =
      Base.encode64(
        "MergeAccount:sthor1nc5tatafv6eyq7llkr2gv50ff9e22mnf70qgjlv737ktmt4eswrqysrzhu/sthor1t4gsjfs8q8j3mw2e402r8vzrtaslsf5re3ktut"
      )

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
  #{@merge_stats_fragment}
  #{@merge_account_fragment}
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
