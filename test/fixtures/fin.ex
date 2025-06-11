defmodule Rujira.Fixtures.Fin do
  alias Rujira.Fin
  import Decimal, only: [new: 1]

  @doc """
  Inserts a flat list of trade‐maps, then updates candles.
  Returns the same list of maps.
  """
  def load_trades_and_candles(pair_address) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    [
      %{
        height:    1,
        tx_idx:    0,
        idx:       1,
        contract:  pair_address,
        txhash:    "txhash1",
        offer:     1_000,
        bid:       2_000,
        rate:      new("2.000000000000"),
        side:      :base,
        protocol:  :fin,
        timestamp: now,
        price:     "fixed:2.0"
      },
      %{
        height:    2,
        tx_idx:    0,
        idx:       2,
        contract:  pair_address,
        txhash:    "txhash2",
        offer:     500,
        bid:       250,
        rate:      new("0.500000000000"),
        side:      :quote,
        protocol:  :fin,
        timestamp: DateTime.add(now, 60, :microsecond),
        price:     "oracle:0.5"
      },
      %{
        height:    3,
        tx_idx:    0,
        idx:       3,
        contract:  pair_address,
        txhash:    "txhash3",
        offer:     1_500,
        bid:       1_500,
        rate:      new("1.000000000000"),
        side:      :base,
        protocol:  :fin,
        timestamp: DateTime.add(now, 120, :microsecond),
        price:     "fixed:1.0"
      }
    ]
    |> Fin.insert_trades()
  end
end
