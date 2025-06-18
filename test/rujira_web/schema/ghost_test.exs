defmodule RujiraWeb.Schema.GhostTest do
  use RujiraWeb.ConnCase
  import RujiraWeb.Fragments.GhostFragments

  @strategies_query """
  query {
    strategies(first: 1, typenames:["GhostVault"]) {
      edges {
        node {
          ...GhostVaultFragment
        }
      }
    }
  }
  #{get_ghost_vault_fragment()}
  """

  @node_query """
  query($id: ID!) {
    node(id: $id) {
      ... on GhostVault {
        ...GhostVaultFragment
      }
    }
  }
  #{get_ghost_vault_fragment()}
  """

  test "list, and lookup vault", %{conn: conn} do
    # 1) fetch all vaults
    conn = post(conn, "/api", %{"query" => @strategies_query})
    %{"data" => %{"strategies" => %{"edges" => edges}}} = json_response(conn, 200)
    assert is_list(edges) and edges != []

    # pick the first vault's Relay global id assert it matches the expected format
    [%{"node" => vault} | _] = edges

    assert vault["id"] == Base.encode64("GhostVault:#{vault["address"]}")

    # 2) node lookup for that vault
    conn = post(conn, "/api", %{"query" => @node_query, "variables" => %{"id" => vault["id"]}})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end
end
