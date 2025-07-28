defmodule RujiraWeb.Schema.VestingTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.VestingFragments

  @list_vesting """
  query {
    vesting(first: 10) {
      edges {
        node {
          ...VestingFragment
        }
      }
    }
  }
  #{get_vesting_fragment()}
  """

  @node_vesting_query """
  query($id: ID!) {
    node(id: $id) {
      ... on Vesting {
        ...VestingFragment
      }
    }
  }
  #{get_vesting_fragment()}
  """

  @account_vesting_query """
  query($layer1Id: ID!) {
    node(id: $layer1Id) {
      ... on Layer1Account {
        id
        account {
          vesting {
            ...VestingAccountFragment
          }
        }
      }
    }
  }
  #{get_vesting_account_fragment()}
  """

  test "vesting functionality", %{
    conn: conn,
    account_populated: account_populated,
    account_empty: account_empty
  } do
    # 1) List all vestings
    conn = post(conn, "/api", %{"query" => @list_vesting})
    %{"data" => %{"vesting" => %{"edges" => edges}}} = json_response(conn, 200)

    if length(edges) > 0 do
      vesting = hd(edges)["node"]

      # 2) Node lookup for individual vesting
      conn =
        post(conn, "/api", %{
          "query" => @node_vesting_query,
          "variables" => %{"id" => vesting["id"]}
        })

      res = json_response(conn, 200)
      assert Map.get(res, "errors") == nil
    end

    # 3) Account-based vesting queries
    for acct <- [account_empty, account_populated] do
      layer1_id = Base.encode64("Layer1Account:thor:#{acct}")

      conn =
        post(conn, "/api", %{
          "query" => @account_vesting_query,
          "variables" => %{"layer1Id" => layer1_id}
        })

      res = json_response(conn, 200)
      assert Map.get(res, "errors") == nil
    end
  end
end
