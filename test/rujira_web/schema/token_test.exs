defmodule RujiraWeb.Schema.TokenTest do
  use RujiraWeb.ConnCase

  import Tesla.Mock

  @assets [
    "BTC.BTC",
    "x/ruji",
    "THOR.TCY",
    "THOR.RUNE"
  ]

  @mock_body_price %{
    "tcy" => %{"usd" => 42.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "bitcoin" => %{"usd" => 100_000.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "rune" => %{"usd" => 100.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000}
  }

  @mock_body_search_by_id %{
    "RUNE" => %{"coins" => [%{"id" => "rune"}]}
  }

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
    mock(fn %Tesla.Env{url: url} ->
      %URI{path: path, query: query} = URI.parse(url)

      case path do
        "/api/v3/simple/price" ->
          %Tesla.Env{status: 200, body: @mock_body_price}

        "/api/v3/search" ->
          params = URI.decode_query(query)

          %Tesla.Env{
            status: 200,
            body: Map.get(@mock_body_search_by_id, params["query"])
          }

        _ ->
          flunk("unexpected HTTP call to #{url}")
      end
    end)

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
