# test/fixtures/league_fixtures.ex
defmodule Rujira.Fixtures.League do
  @moduledoc "Fixtures for League-related schemas"
  alias Rujira.Leagues

  def load_league do
    tx_payloads = [
      %{
        height: 1,
        idx: 1,
        txhash: "txhash1",
        timestamp: DateTime.utc_now(),
        address: "sthor1uuds8pd92qnnq0udw0rpg0szpgcslc9ph3j6kf",
        revenue: 1000,
        category: :swap
      },
      %{
        height: 1,
        idx: 2,
        txhash: "txhash2",
        timestamp: DateTime.utc_now(),
        address: "sthor1BBB…",
        revenue: 900,
        category: :swap
      },
      %{
        height: 1,
        idx: 3,
        txhash: "txhash3",
        timestamp: DateTime.utc_now(),
        address: "sthor1CCC…",
        revenue: 800,
        category: :trade
      }
    ]

    inserted_tx_rows = Leagues.insert_tx_events(tx_payloads)

    Leagues.update_leagues(inserted_tx_rows)
  end
end
