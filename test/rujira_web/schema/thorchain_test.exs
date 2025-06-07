defmodule RujiraWeb.Schema.ThorchainTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.ThorchainFragments

  @query """
  query {
    thorchainV2 {
      inboundAddresses {
        ...ThorchainInboundAddressFragment
      }
    }
  }
  #{get_thorchain_inbound_address_fragment()}
  """

  test "inbound addresses", %{conn: conn} do
    conn = post(conn, "/api", %{"query" => @query})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on ThorchainInboundAddress {
        ...ThorchainInboundAddressFragment
      }
    }
  }
  #{get_thorchain_inbound_address_fragment()}
  """

  test "inbound address", %{conn: conn} do
    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => Base.encode64("ThorchainInboundAddress:BTC")}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query {
    thorchainV2 {
      pools {
        ...ThorchainPoolFragment
      }
    }
  }
  #{get_thorchain_pool_fragment()}
  """

  test "pools", %{conn: conn} do
    conn = post(conn, "/api", %{"query" => @query})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on ThorchainPool {
        ...ThorchainPoolFragment
      }
    }
  }
  #{get_thorchain_pool_fragment()}
  """

  test "pool", %{conn: conn} do
    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => Base.encode64("ThorchainPool:BTC.BTC")}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end
end
