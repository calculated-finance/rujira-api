defmodule RujiraWeb.Schema.TokenTest do
  alias RujiraWeb.Fragments.AssetFragments
  use RujiraWeb.ConnCase

  @asset_fragment AssetFragments.get_asset_fragment()

  @assets [
    "BTC.BTC",
    "x/ruji",
    "THOR.TCY",
    "THOR.RUNE"
  ]

  @query """
  query($ids: [ID!]!) {
    nodes(ids: $ids) {
      ...AssetFragment
    }
  }
  #{@asset_fragment}
  """

  test "assets", %{conn: conn} do
    assets =
      @assets
      |> Enum.map(&Base.encode64("Asset:#{&1}"))

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"ids" => assets}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end
end
