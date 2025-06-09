defmodule RujiraWeb.Schema.BowTest do
  use RujiraWeb.ConnCase
  import RujiraWeb.Fragments.BowFragments

  @accounts Application.compile_env(:rujira, :accounts)
  @empty_account Keyword.fetch!(@accounts, :empty_account)
  @populated_account Keyword.fetch!(@accounts, :populated_account)

  @pool_query """
  query {
    bow {
      ...BowPoolFragment
    }
  }
  #{get_bow_pool_fragment()}
  """

  @node_query """
  query($id: ID!) {
    node(id: $id) {
      ... on BowPool {
        ...BowPoolFragment
      }
    }
  }
  #{get_bow_pool_fragment()}
  """

  @account_query """
  query($layer1Id: ID!) {
    node(id: $layer1Id) {
      ... on Layer1Account {
        id
        account {
          bow {
            ...BowAccountFragment
          }
        }
      }
    }
  }
  #{get_bow_account_fragment()}
  """

  test "list, lookup and layer1-account bow flows", %{conn: conn} do
    # 1) fetch all pools
    conn = post(conn, "/api", %{"query" => @pool_query})
    %{"data" => %{"bow" => pools}} = json_response(conn, 200)
    assert is_list(pools) and pools != []

    # pick the first pool's Relay global id assert it matches the expected format
    pool = hd(pools)
    assert pool["id"] == Base.encode64("BowPool:#{pool["address"]}")

    # 2) node lookup for that pool
    conn = post(conn, "/api", %{"query" => @node_query, "variables" => %{"id" => pool["id"]}})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil

    # 3) for both empty & populated accounts, check that the account.bow list resolves
    for acct <- [@empty_account, @populated_account] do
      layer1_id = Base.encode64("Layer1Account:thor:#{acct}")

      conn =
        post(conn, "/api", %{
          "query" => @account_query,
          "variables" => %{"layer1Id" => layer1_id}
        })

      res = json_response(conn, 200)
      assert Map.get(res, "errors") == nil
    end
  end
end
