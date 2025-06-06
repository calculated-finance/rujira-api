defmodule RujiraWeb.Schema.ThorchainTest do
  use RujiraWeb.ConnCase

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
  end
end
