defmodule RujiraWeb.Schema.FinTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.FinFragments
  import Mox

  setup :verify_on_exit!

  @list_query """
  query {
    fin {
      ...FinPairFragment
    }
  }
  #{get_fin_pair_fragment()}
  """

  @node_query """
  query($id: ID!) {
    node(id: $id) {
      ... on FinPair {
        ...FinPairFragment
      }
    }
  }
  #{get_fin_pair_fragment()}
  """

  @candles_query """
  query($after: String!, $before: String!, $resolution: String!) {
    fin {
      candles(after: $after, before: $before, resolution: $resolution) {
        edges {
          node {
            ...FinCandleFragment
          }
        }
      }
    }
  }
  #{get_fin_candle_fragment()}
  """

  test "fin list, node lookup and candles all work without hard-coding addresses", %{conn: conn} do
    # 1) list
    resp = post(conn, "/api", %{"query" => @list_query})
    %{"data" => %{"fin" => pairs}} = json_response(resp, 200)
    assert is_list(pairs) and pairs != []

    # pick the first one
    pair = hd(pairs)
    assert pair["id"] == Base.encode64("FinPair:#{pair["address"]}")

    # 2) node lookup
    resp = post(conn, "/api", %{
      "query"     => @node_query,
      "variables" => %{"id" => pair["id"]}
    })
    res = json_response(resp, 200)
    assert Map.get(res, "errors") == nil

    # 3) candles: seed fixtures, stub swallow publish
    stub(Rujira.Events.PublisherMock, :publish, fn _, _, _ -> :ok end)
    Rujira.Fixtures.Fin.load_trades_and_candles(pair["address"])

    resp = post(conn, "/api", %{
      "query"     => @candles_query,
      "variables" => %{
        "after"      => "2025-06-01T00:00:00Z",
        "before"     => "2025-06-08T00:00:00Z",
        "resolution" => "1h"
      }
    })
    res = json_response(resp, 200)
    assert Map.get(res, "errors") == nil
  end
end
