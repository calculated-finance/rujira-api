defmodule RujiraWeb.Schema.FinTest do
  use RujiraWeb.ConnCase

  alias Rujira.Deployments

  import RujiraWeb.Fragments.FinFragments
  import Mox

  setup :verify_on_exit!

  defp flush_publishes(acc \\ []) do
    receive do
      {:published, _endpoint, _payload, _topics} = msg ->
        flush_publishes([msg | acc])
    after
      0 ->
        Enum.reverse(acc)
    end
  end

  @query """
  query {
    fin {
      ...FinPairFragment
    }
  }
  #{get_fin_pair_fragment()}
  """

  test "fin", %{conn: conn} do
    conn = post(conn, "/api", %{"query" => @query})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on FinPair {
        ...FinPairFragment
      }
    }
  }
  #{get_fin_pair_fragment()}
  """

  test "fin pair", %{conn: conn} do
    fin_pair = Deployments.get_target(Rujira.Fin.Pair, "ruji-rune")

    encoded_id = Base.encode64("FinPair:#{fin_pair.address}")

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => encoded_id}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
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

  test "fin candles", %{conn: conn} do
    pair_address = Deployments.get_target(Rujira.Fin.Pair, "ruji-rune").address

    stub(Rujira.Events.PublisherMock, :publish, fn endpoint, payload, topics ->
      send(self(), {:published, endpoint, payload, topics})
      :ok
    end)

    Rujira.Fixtures.Fin.load_trades_and_candles(pair_address)

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{
          "after" => "2025-06-01T00:00:00Z",
          "before" => "2025-06-08T00:00:00Z",
          "resolution" => "1h"
        }
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil

    published = flush_publishes()
    # 42 published messages for 3 trades as:
    # 2 for each trade one node and one edge (3) -> 6
    # 1 for each candle resolution (12 in total) for each trade -> 3 * 12 = 36
    assert length(published) == 42
  end
end
