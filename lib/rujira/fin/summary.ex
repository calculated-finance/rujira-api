defmodule Rujira.Fin.Summary do
  alias Rujira.Fin.Trade
  import Ecto.Query

  defstruct [:id, :last, :last_usd, :high, :low, :change, :volume]

  @type t :: %__MODULE__{
          id: String.t(),
          last: Decimal.t(),
          high: Decimal.t(),
          low: Decimal.t(),
          change: Decimal.t(),
          volume: non_neg_integer()
        }

  def query() do
    contracts =
      from(t in Trade,
        distinct: t.contract,
        select: %{contract: t.contract, last: t.rate},
        order_by: {:desc, :timestamp}
      )

    windows =
      from(t in Trade,
        select: %{
          id: t.contract,
          first: over(first_value(t.rate), :p),
          last: over(last_value(t.rate), :p),
          high: over(max(t.rate), :p),
          low: over(min(t.rate), :p),
          volume:
            over(
              sum(
                fragment(
                  "CASE WHEN ? = ? THEN ? ELSE ? END",
                  t.side,
                  "quote",
                  t.bid,
                  t.offer
                )
              ),
              :p
            )
        },
        distinct: t.contract,
        windows: [p: [partition_by: t.contract]]
      )

    from(c in subquery(contracts),
      left_join: s in subquery(windows),
      on: c.contract == s.id,
      select: %__MODULE__{
        id: s.id,
        last: fragment("COALESCE(?, ?)", s.last, c.last),
        high: fragment("COALESCE(?, ?)", s.high, c.last),
        low: fragment("COALESCE(?, ?)", s.low, c.last),
        change: fragment("COALESCE((? - ?) / ?, 0)", s.last, s.first, s.first),
        volume: fragment("COALESCE(?, ?)::bigint", s.volume, 0)
      }
    )
    |> subquery()
  end
end
