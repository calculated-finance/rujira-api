defmodule RujiraWeb.Schema.TokenTest do
  use RujiraWeb.ConnCase

  @assets [
    "BTC-BTC",
    "RUNE",
    "x/ruji"
  ]

  @metadata_fragment """
  fragment MetadataFragment on Metadata {
    symbol
    decimals
    description
    display
    name
    uri
    uriHash
  }
  """

  @price_fragment """
  fragment PriceFragment on Price {
    id
    source
    current
    changeDay
    mcap
    timestamp
  }
  """

  @denom_fragment """
  fragment DenomFragment on Denom {
    denom
  }
  """

  @asset_fragment_simple """
  fragment AssetFragmentSimple on Asset {
    id
    asset
    type
    chain
  }
  """

  @asset_variants_fragment """
  fragment AssetVariantsFragment on AssetVariants {
    layer1 {
      ...AssetFragmentSimple
    }
    secured {
      ...AssetFragmentSimple
    }
    native {
      ...DenomFragment
    }
  }
  #{@denom_fragment}
  #{@asset_fragment_simple}
  """

  @asset_fragment """
  fragment AssetFragment on Asset {
    id
    asset
    type
    chain
    metadata {
      ...MetadataFragment
    }
    price {
      ...PriceFragment
    }
    variants {
      ...AssetVariantsFragment
    }
  }
  #{@metadata_fragment}
  #{@price_fragment}
  #{@asset_variants_fragment}
  """

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
