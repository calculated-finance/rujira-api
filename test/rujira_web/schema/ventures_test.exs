defmodule RujiraWeb.Schema.VenturesTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.VenturesFragments
  import RujiraWeb.Fragments.PilotFragments

  @config_query """
  query {
    ventures {
      config {
        ...VenturesConfigFragment
      }
    }
  }
  #{get_ventures_config_fragment()}
  """

  test "ventures config", %{conn: conn} do
    resp = post(conn, "/api", %{"query" => @config_query})
    res = json_response(resp, 200)
    assert Map.get(res, "errors") == nil
  end

  @sales_query """
  query($first: Int!, $status: [VenturesSaleStatus!]) {
    ventures {
      sales(first: $first, status: $status) {
        edges {
          node {
            ...VenturesSaleFragment
          }
        }
      }
    }
  }
  #{get_ventures_sale_fragment()}
  """

  @sale_query """
  query($id: ID!) {
    node(id: $id) {
      ... on VenturesSale {
        ...VenturesSaleFragment
      }
    }
  }
  #{get_ventures_sale_fragment()}
  """

  @bid_pools_query """
  query($id: ID!) {
    node(id: $id) {
      ... on PilotBidPools {
        ...PilotPoolsFragment
      }
    }
  }
  #{get_pilot_pools_fragment()}
  """

  test "ventures sales", %{conn: conn} do
    # without variables
    resp =
      post(conn, "/api", %{
        "query" => @sales_query,
        "variables" => %{"first" => 1, "status" => ["IN_PROGRESS", "COMPLETED"]}
      })

    res = json_response(resp, 200)
    assert Map.get(res, "errors") == nil

    # get the first and query node
    sale = hd(res["data"]["ventures"]["sales"]["edges"])

    resp =
      post(conn, "/api", %{"query" => @sale_query, "variables" => %{"id" => sale["node"]["id"]}})

    res = json_response(resp, 200)
    assert Map.get(res, "errors") == nil

    # query the bid pools node
    resp =
      post(conn, "/api", %{
        "query" => @bid_pools_query,
        "variables" => %{"id" => sale["node"]["venture"]["sale"]["bidPools"]["id"]}
      })

    res = json_response(resp, 200)
    assert Map.get(res, "errors") == nil
  end
end
