defmodule RujiraWeb.Schema.IndexTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.IndexFragments

  @list_vaults """
  query {
    index {
      ...IndexVaultFragment
    }
  }
  #{get_index_vault_fragment()}
  """

  @node_query """
  query($id: ID!) {
    node(id: $id) {
      ... on IndexVault {
        ...IndexVaultFragment
      }
    }
  }
  #{get_index_vault_fragment()}
  """

  @account_query """
  query($layer1Id: ID!) {
    node(id: $layer1Id) {
      ... on Layer1Account {
        id
        account {
          index {
            ...IndexAccountFragment
          }
        }
      }
    }
  }
  #{get_index_account_fragment()}
  """

  test "Vaults tests", %{
    conn: conn,
    account_populated: account_populated,
    account_empty: account_empty
  } do
    conn = post(conn, "/api", %{"query" => @list_vaults})
    %{"data" => %{"index" => vaults}} = json_response(conn, 200)

    vault = hd(vaults)
    assert vault["id"] == Base.encode64("IndexVault:#{vault["address"]}")

    # 2) node lookup for that vault
    conn = post(conn, "/api", %{"query" => @node_query, "variables" => %{"id" => vault["id"]}})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil

    # 3) for both empty & populated accounts, check that the account vault list resolves
    for acct <- [account_empty, account_populated] do
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
