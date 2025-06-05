defmodule RujiraWeb.Schema.ThorchainTest do
  use RujiraWeb.ConnCase

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
    %{"data" => %{"thorchainV2" => %{"pools" => pools}}} = res
    assert Enum.count(pools) > 0
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
end
