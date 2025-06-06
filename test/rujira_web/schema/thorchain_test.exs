defmodule RujiraWeb.Schema.ThorchainTest do
  use RujiraWeb.ConnCase
  import RujiraWeb.Schema.GQLTestMacros

  @inbound_address_fragment """
  fragment ThorchainInboundAddressFragment on ThorchainInboundAddress {
    address
    chain
    chainLpActionsPaused
    chainTradingPaused
    dustThreshold
    gasRate
    gasRateUnits
    globalTradingPaused
    halted
    id
    outboundFee
    outboundTxSize
    pubKey
    router
  }
  """

  @pool_fragment """
  fragment ThorchainPoolFragment on ThorchainPool {
    asset {
      asset
    }
    assetTorPrice
    balanceAsset
    balanceRune
    decimals
    derivedDepthBps
    id
    loanCollateral
    loanCollateralRemaining
    loanCr
    lpUnits
    pendingInboundAsset
    pendingInboundRune
    poolUnits
    saversCapacityRemaining
    saversDepth
    saversFillBps
    saversUnits
    shortCode
    status
    synthMintPaused
    synthSupply
    synthSupplyRemaining
    synthUnits
    candles(
        after: "2025-06-05T00:00:00Z",
        before: "2025-06-06T00:00:00Z",
        resolution: "1"
      ) {
      edges {
        node {
          bin
          close
          high
          low
          open
          resolution
        }
      }
    }
  }
  """

  @query """
  query {
    thorchainV2 {
      inboundAddresses {
        ...ThorchainInboundAddressFragment
      }
    }
  }
  #{@inbound_address_fragment}
  """

  test "inbound addresses", %{conn: conn} do
    conn = post(conn, "/api", %{"query" => @query})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
    %{"data" => %{"thorchainV2" => %{"inboundAddresses" => [_ | _]}}} = res
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on ThorchainInboundAddress {
        ...ThorchainInboundAddressFragment
      }
    }
  }
  #{@inbound_address_fragment}
  """

  test "inbound address", %{conn: conn} do
    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => Base.encode64("ThorchainInboundAddress:BTC")}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil

    %{
      "data" => %{
        "node" => %{
          "address" => "bc1" <> _,
          "chain" => "BTC",
          "chainLpActionsPaused" => _,
          "chainTradingPaused" => _,
          "dustThreshold" => _,
          "gasRate" => _,
          "gasRateUnits" => _,
          "globalTradingPaused" => _,
          "halted" => _,
          "id" => _,
          "outboundFee" => _,
          "outboundTxSize" => _,
          "pubKey" => "sthor" <> _,
          "router" => _
        }
      }
    } = res
  end

  @query """
  query {
    thorchainV2 {
      pools {
        ...ThorchainPoolFragment
      }
    }
  }
  #{@pool_fragment}
  """

  test "pools", %{conn: conn} do
    conn = post(conn, "/api", %{"query" => @query})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
    %{"data" => %{"thorchainV2" => %{"pools" => [_ | _]}}} = res
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on ThorchainPool {
        ...ThorchainPoolFragment
      }
    }
  }
  #{@pool_fragment}
  """

  test "pool", %{conn: conn} do
    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => Base.encode64("ThorchainPool:BTC.BTC")}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil

    %{
      "data" => %{
        "node" => %{
          "asset" => %{"asset" => "BTC.BTC"},
          "assetTorPrice" => _,
          "balanceAsset" => _,
          "balanceRune" => _,
          "decimals" => _,
          "derivedDepthBps" => _,
          "id" => _,
          "loanCollateral" => _,
          "loanCollateralRemaining" => _,
          "loanCr" => _,
          "lpUnits" => _,
          "pendingInboundAsset" => _,
          "pendingInboundRune" => _,
          "poolUnits" => _,
          "saversCapacityRemaining" => _,
          "saversDepth" => _,
          "saversFillBps" => _,
          "saversUnits" => _,
          "shortCode" => _,
          "status" => _,
          "synthMintPaused" => _,
          "synthSupply" => _,
          "synthSupplyRemaining" => _,
          "synthUnits" => _
        }
      }
    } = res
  end

  @gql_tests [
    %{
      name: "inbound addresses",
      query: """
      query {
        thorchainV2 {
          inboundAddresses {
            ...ThorchainInboundAddressFragment
          }
        }
      }
      #{@inbound_address_fragment}
      """,
      variables: %{},
      # path into JSON response where the “list of objects” lives:
      response_path: ["data", "thorchainV2", "inboundAddresses"],
      type_name: "ThorchainInboundAddress",
      is_list: true
    },
    %{
      name: "pool",
      query: """
      query($id: ID!) {
        node(id: $id) {
          ... on ThorchainPool {
            ...ThorchainPoolFragment
          }
        }
      }
      #{@pool_fragment}
      """,
      variables: %{"id" => Base.encode64("ThorchainPool:BTC.BTC")},
      # path into JSON response where the “list of objects” lives:
      response_path: ["data", "node"],
      type_name: "ThorchainPool",
      is_list: false
    }
  ]

  generate_gql_tests(@gql_tests)
end
