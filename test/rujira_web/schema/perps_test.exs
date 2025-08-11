defmodule RujiraWeb.Schema.PerpsTest do
  use RujiraWeb.ConnCase
  import RujiraWeb.Fragments.PerpsFragments
  import Tesla.Mock

  @pool_query """
  query {
    perps {
      ...PerpsPoolFragment
    }
  }
  #{get_perps_pool_fragment()}
  """

  @node_query """
  query($id: ID!) {
    node(id: $id) {
      ... on PerpsPool {
        ...PerpsPoolFragment
      }
    }
  }
  #{get_perps_pool_fragment()}
  """

  test "list, lookup and layer1-account perps flows", %{
    conn: conn
  } do
    mock(fn
      %{
        method: :get,
        url:
          "https://indexer-mainnet.levana.finance/v2/markets-earn-data?network=rujira-mainnet&factory=thor1gclfrvam6a33yhpw3ut3arajyqs06esdvt9pfvluzwsslap9p6uqt4rzxs"
      } ->
        %Tesla.Env{status: 200, body: %{}}
    end)

    # 1) fetch all pools
    conn = post(conn, "/api", %{"query" => @pool_query})
    %{"data" => %{"perps" => pools}} = json_response(conn, 200)
    assert is_list(pools) and pools != []

    # pick the first pool's Relay global id assert it matches the expected format
    pool = hd(pools)
    assert pool["id"] == Base.encode64("PerpsPool:#{pool["address"]}")

    # 2) node lookup for that pool
    conn = post(conn, "/api", %{"query" => @node_query, "variables" => %{"id" => pool["id"]}})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end
end
