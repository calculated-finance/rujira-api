defmodule RujiraWeb.Schema.ThorchainTest do
  use RujiraWeb.ConnCase

  @query """
  query thorchain {
    thorchainV2 {
      pools {
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
    }
  }
  """

  test "query: pools", %{conn: conn} do
    conn = post(conn, "/api", %{"query" => @query})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
    %{"data" => %{"thorchainV2" => %{"pools" => pools}}} = res
    assert Enum.count(pools) > 0
  end
end
