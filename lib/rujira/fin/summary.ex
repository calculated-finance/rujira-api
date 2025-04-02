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
        order_by: [desc: :height, desc: :tx_idx, desc: :idx]
      )

    aggregates =
      from(t in Trade,
        where: fragment("? > NOW() - INTERVAL '1 day'", t.timestamp),
        group_by: t.contract,
        select: %{
          id: t.contract,
          open:
            fragment(
              "(SELECT rate FROM trades WHERE contract = ? AND timestamp > NOW() - INTERVAL '1 day' ORDER BY height ASC, tx_idx ASC, idx ASC LIMIT 1)",
              t.contract
            ),
          close:
            fragment(
              "(SELECT rate FROM trades WHERE contract = ? AND timestamp > NOW() - INTERVAL '1 day' ORDER BY height DESC, tx_idx DESC, idx DESC LIMIT 1)",
              t.contract
            ),
          high: max(t.rate),
          low: min(t.rate),
          volume:
            sum(
              fragment(
                "CASE WHEN ? = 'quote' THEN ? ELSE ? END",
                t.side,
                t.bid,
                t.offer
              )
            )
        }
      )

    from(c in subquery(contracts),
      left_join: a in subquery(aggregates),
      on: c.contract == a.id,
      select: %__MODULE__{
        id: c.contract,
        last: fragment("COALESCE(?, ?)", a.close, c.last),
        high: fragment("COALESCE(?, ?)", a.high, c.last),
        low: fragment("COALESCE(?, ?)", a.low, c.last),
        # % change = (close - open) / open
        change: fragment("COALESCE((? - ?) / NULLIF(?, 0), 0)", a.close, a.open, a.open),
        volume: fragment("COALESCE(?, 0)::bigint", a.volume)
      }
    )
    |> subquery()
  end
end
