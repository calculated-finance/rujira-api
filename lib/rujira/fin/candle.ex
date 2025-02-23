defmodule Rujira.Fin.Candle do
  alias Rujira.Fin.Trades
  alias Rujira.Repo
  alias Rujira.Fin.Trades.Trade
  alias Rujira.Fin.TradingView
  import Ecto.Query

  defstruct [
    :id,
    :bin,
    :open,
    :close,
    :high,
    :low,
    :volume
  ]

  def list_candles(contract, from, to, precision) do
    Trade
    |> where([t], t.timestamp >= ^from and t.contract == ^contract)
    |> Trades.sort(:desc)
    |> subquery()
    |> TradingView.with_range(from, to, precision)
    |> join(:right, [t], b in "bins",
      on:
        t.timestamp >= b.min and
          t.timestamp < b.max and
          t.contract == ^contract
    )
    |> select([t, b], %{
      bin: b.min,
      timestamp: t.timestamp,
      trade_price: t.rate,
      bid: t.bid,
      high: over(max(t.rate), :bins),
      low: over(min(t.rate), :bins),
      open: over(first_value(t.rate), :bins),
      close: over(last_value(t.rate), :bins),
      volume: over(sum(t.bid), :bins),
      rank: over(rank(), :bins),
      row_number: over(row_number(), :bins)
    })
    |> windows([t, b],
      bins: [
        partition_by: b.min,
        order_by: t.timestamp,
        frame: fragment("RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING")
      ]
    )
    |> subquery()
    |> group_by([:bin, :open, :close, :high, :low, :volume])
    |> select([b], %{
      id: fragment("concat(?::varchar, '/', ?)", ^precision, b.bin),
      bin: b.bin,
      high: b.high,
      low: b.low,
      open: b.open,
      close: b.close,
      volume: coalesce(b.volume, 0)
    })
    |> order_by(asc: :bin)
    |> Repo.all()
    |> fill_blanks()
    |> Enum.reverse()
    |> Enum.map(&struct(__MODULE__, &1))
  end

  defp fill_blanks(agg \\ [], _rem)

  # If this is a first item and it's blank, drop it
  defp fill_blanks([], [%{close: nil, high: nil, low: nil, open: nil} | rest]) do
    fill_blanks([], rest)
  end

  defp fill_blanks([prev | agg], [%{close: nil, high: nil, low: nil, open: nil} = el | rest]) do
    filled = %{el | close: prev.close, high: prev.close, low: prev.close, open: prev.close}
    fill_blanks([filled, prev | agg], rest)
  end

  defp fill_blanks(agg, [x | rest]), do: fill_blanks([x | agg], rest)
  defp fill_blanks(agg, []), do: agg

  def to_id(address, res, bin) do
    "#{address}:#{res}:#{DateTime.to_unix(bin)}"
  end
end
