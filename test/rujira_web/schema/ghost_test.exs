defmodule RujiraWeb.Schema.GhostTest do
  use RujiraWeb.ConnCase
  import RujiraWeb.Fragments.GhostFragments

  import Tesla.Mock

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
    mock(fn
      %{
        method: :get,
        url:
          "https://indexer-mainnet.levana.finance/v2/markets-earn-data?network=rujira-mainnet&factory=thor1gclfrvam6a33yhpw3ut3arajyqs06esdvt9pfvluzwsslap9p6uqt4rzxs"
      } ->
        %Tesla.Env{status: 200, body: %{}}
    end)

    # 1) fetch all vaults
    conn = post(conn, "/api", %{"query" => @strategies_query})
    %{"data" => %{"strategies" => %{"edges" => edges}}} = res = json_response(conn, 200)
    assert is_list(edges) and edges != []
    assert Map.get(res, "errors") == nil

    # pick the first vault's Relay global id assert it matches the expected format
    [%{"node" => vault} | _] = edges

    assert vault["id"] == Base.encode64("GhostVault:#{vault["address"]}")

    # 2) node lookup for that vault
    conn = post(conn, "/api", %{"query" => @node_query, "variables" => %{"id" => vault["id"]}})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end
end
