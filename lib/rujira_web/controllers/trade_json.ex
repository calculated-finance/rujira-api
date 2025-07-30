defmodule RujiraWeb.TradeJSON do
  alias Rujira.Assets
  alias Rujira.Fin
  alias Rujira.Fin.Book
  alias Rujira.Fin.Book.Price
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Trade

  def render("tickers.json", %{pairs: pairs, summaries: summaries}) do
    for(pair <- pairs, do: ticker(pair, Enum.find(summaries, %{}, &(&1.id == pair.id))))
  end

  def render("orderbook.json", %{
        pair: %Pair{book: %Book{bids: bids, asks: asks}} = pair
      }) do
    %{
      ticker_id: Fin.ticker_id!(pair),
      # timestamp: NaiveDateTime.utc_now(:second),
      bids: for(bid <- bids, do: entry(bid)),
      asks: for(ask <- asks, do: entry(ask))
    }
  end

  def render("trades.json", %{trades: trades}) do
    for(trade <- trades, do: history(trade))
  end

  def entry(%Price{price: price, total: total}) do
    [price, amount(total)]
  end

  def ticker(
        %Pair{
          id: id,
          token_base: token_base,
          token_quote: token_quote,
          book: %Book{bids: bids, asks: asks}
        } = pair,
        summary
      ) do
    {:ok, base} = Assets.from_denom(token_base)
    {:ok, target} = Assets.from_denom(token_quote)
    %{price: bid} = Enum.at(bids, 0, %{price: nil})
    %{price: ask} = Enum.at(asks, 0, %{price: nil})

    %{
      pair_id: id,
      ticker_id: Fin.ticker_id!(pair),
      base_currency: Assets.label(base),
      target_currency: Assets.label(target),
      last_price: Map.get(summary, :last),
      base_volume: Map.get(summary, :volume_base) |> amount(),
      target_volume: Map.get(summary, :volume) |> amount(),
      bid: bid,
      ask: ask
    }
  end

  def history(%Trade{
        id: id,
        rate: rate,
        quote_amount: quote_amount,
        base_amount: base_amount,
        type: type,
        timestamp: timestamp
      }) do
    %{
      trade_id: id,
      price: rate,
      base_volume: amount(base_amount),
      target_volume: amount(quote_amount),
      trade_timestamp: DateTime.to_unix(timestamp, :millisecond),
      type: type
    }
  end

  defp amount(nil), do: Decimal.new(0)
  defp amount(v), do: Decimal.div(Decimal.new(v), Decimal.new(100_000_000))
end
