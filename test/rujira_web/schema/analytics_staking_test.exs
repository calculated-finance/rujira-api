defmodule RujiraWeb.Schema.AnalyticsStakingTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.AnalyticsStakingFragments
  import Mox
  alias Rujira.Analytics.Staking.Indexer
  alias Rujira.Fixtures.Block

  setup :verify_on_exit!

  @bins_connection_query """
  query($from: Timestamp!, $to: Timestamp!, $contract: Address!, $resolution: Resolution!, $period: Int!, $first: Int!) {
    analytics {
      staking {
        bins(
          from: $from
          to: $to
          contract: $contract
          resolution: $resolution
          period: $period
          first: $first
        ) {
          ...AnalyticsStakingConnectionFragment
        }
      }
    }
  }
  #{get_analytics_staking_connection_fragment()}
  """

  test "staking analytics", %{conn: conn} do
    param = %{
      "from" => "2025-01-01T00:00:00Z",
      "to" => "2026-12-31T23:59:59Z",
      "contract" => "sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj",
      "resolution" => "1D",
      "period" => 7,
      "first" => 10
    }

    response =
      post(conn, "/api", %{
        "query" => @bins_connection_query,
        "variables" => param
      })
      |> json_response(200)

    # empty
    assert Map.get(response, "errors") == nil

    assert %{"data" => %{"analytics" => %{"staking" => %{"bins" => %{"edges" => edges}}}}} =
             response

    assert Enum.empty?(edges)

    # populate the database
    stub(Rujira.Events.PublisherMock, :publish, fn _, _, _ -> :ok end)
    {:ok, block} = Block.load_block("5334888")

    {:ok, pool} =
      Rujira.Staking.get_pool("sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj")

    # index the block to collect staking data
    Indexer.handle_new_block(block, pool)

    # query again
    response =
      post(conn, "/api", %{
        "query" => @bins_connection_query,
        "variables" => param
      })
      |> json_response(200)

    assert Map.get(response, "errors") == nil

    assert %{"data" => %{"analytics" => %{"staking" => %{"bins" => %{"edges" => edges}}}}} =
             response

    assert length(edges) == 1

    # block 5451582
    # Deposit 1 RUJI
    {:ok, block} = Block.load_block("5451582")

    # index the block to collect staking data
    Indexer.handle_new_block(block, pool)

    # query again
    response =
      post(conn, "/api", %{
        "query" => @bins_connection_query,
        "variables" => param
      })
      |> json_response(200)

    assert Map.get(response, "errors") == nil

    assert %{"data" => %{"analytics" => %{"staking" => %{"bins" => %{"edges" => edges}}}}} =
             response

    assert length(edges) == 2

    # credo:disable-for-next-line Credo.Check.Warning.IoInspect
    IO.inspect(Enum.at(edges, 1), label: "Deposit 1 RUJI inflow of 100_000_000")

    # block 5451594
    # Distribute 0.5 Usdt
    {:ok, block} = Block.load_block("5451594")

    # index the block to collect staking data
    Indexer.handle_new_block(block, pool)

    # query again
    response =
      post(conn, "/api", %{
        "query" => @bins_connection_query,
        "variables" => param
      })
      |> json_response(200)

    assert Map.get(response, "errors") == nil

    assert %{"data" => %{"analytics" => %{"staking" => %{"bins" => %{"edges" => edges}}}}} =
             response

    assert length(edges) == 2

    # credo:disable-for-next-line Credo.Check.Warning.IoInspect
    IO.inspect(Enum.at(edges, 1),
      label: "Distribute 0.5 Usdt revenue of 50_000_000 * price of usdt"
    )

    # block 5451604
    # Deposit 0.69 ruji liquid
    {:ok, block} = Block.load_block("5451604")

    # index the block to collect staking data
    Indexer.handle_new_block(block, pool)

    # query again
    response =
      post(conn, "/api", %{
        "query" => @bins_connection_query,
        "variables" => param
      })
      |> json_response(200)

    assert Map.get(response, "errors") == nil

    assert %{"data" => %{"analytics" => %{"staking" => %{"bins" => %{"edges" => edges}}}}} =
             response

    assert length(edges) == 2

    # credo:disable-for-next-line Credo.Check.Warning.IoInspect
    IO.inspect(Enum.at(edges, 1), label: "Deposit 0.69 ruji liquid inflow of 69_000_000")

    # block 5451618
    # Withdraw 2 ruji
    {:ok, block} = Block.load_block("5451618")

    # index the block to collect staking data
    Indexer.handle_new_block(block, pool)

    # query again
    response =
      post(conn, "/api", %{
        "query" => @bins_connection_query,
        "variables" => param
      })
      |> json_response(200)

    assert Map.get(response, "errors") == nil

    assert %{"data" => %{"analytics" => %{"staking" => %{"bins" => %{"edges" => edges}}}}} =
             response

    assert length(edges) == 2

    # credo:disable-for-next-line Credo.Check.Warning.IoInspect
    IO.inspect(Enum.at(edges, 1), label: "Withdraw 2 ruji outflow of 200_000_000")

    # block 5451627
    # Withdraw 1 ruji liquid
    {:ok, block} = Block.load_block("5451627")

    # index the block to collect staking data
    Indexer.handle_new_block(block, pool)

    # query again
    response =
      post(conn, "/api", %{
        "query" => @bins_connection_query,
        "variables" => param
      })
      |> json_response(200)

    assert Map.get(response, "errors") == nil

    assert %{"data" => %{"analytics" => %{"staking" => %{"bins" => %{"edges" => edges}}}}} =
             response

    assert length(edges) == 2

    # credo:disable-for-next-line Credo.Check.Warning.IoInspect
    IO.inspect(Enum.at(edges, 1), label: "Withdraw 1 ruji liquid outflow of 100_000_000")
  end
end
