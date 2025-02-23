defmodule RujiraWeb.Resolvers.Fin do
  alias Rujira.Fin.Trades.Trade
  alias Rujira.Fin.Trades
  alias Rujira.Assets
  alias Rujira.Fin
  alias Absinthe.Resolution.Helpers

  def node(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, pair} <- Rujira.Fin.get_pair(address),
           {:ok, pair} <- Rujira.Fin.load_pair(pair) do
        {:ok, pair}
      end
    end)
  end

  def resolver(_, _, _) do
    Helpers.async(fn ->
      with {:ok, pairs} <- Rujira.Fin.list_pairs() do
        {:ok, pairs}
      end
    end)
  end

  def book(%{book: :not_loaded} = pair, _, _) do
    with {:ok, %{book: book}} <- Rujira.Fin.load_pair(pair) do
      {:ok, book}
    end
  end

  def book(%{book: book}, _, _), do: {:ok, book}

  def trades(%{address: address, token_base: token_base, token_quote: token_quote}, _, _) do
    with {:ok, trades} <- Trades.list_trades(address),
         {:ok, asset_base} <- Assets.from_denom(token_base),
         {:ok, asset_quote} <- Assets.from_denom(token_quote) do
      {:ok,
       %{
         page_info: %{
           start_cursor: <<>>,
           end_cursor: <<>>,
           has_previous_page: false,
           has_next_page: false
         },
         edges:
           Enum.map(
             trades,
             &resolve_trade(&1, asset_base, asset_quote)
           )
       }}
    end
  end

  defp resolve_trade(%Trade{} = t, asset_base, asset_quote) do
    {base_amount, quote_amount} =
      if t.side == "base", do: {t.bid, t.offer}, else: {t.offer, t.bid}

    %{
      cursor: t.id,
      node: %{
        id: t.id,
        height: t.height,
        tx_idx: t.tx_idx,
        idx: t.idx,
        contract: t.contract,
        txhash: t.txhash,
        quote_amount: quote_amount,
        base_amount: base_amount,
        price: t.rate,
        type: if(t.side == "base", do: "buy", else: "sell"),
        protocol: t.protocol,
        timestamp: t.timestamp,
        asset_base: asset_base,
        asset_quote: asset_quote
      }
    }
  end

  def summary(%{token_base: base, token_quote: quot}, _, _) do
    {:ok, base} = Assets.from_denom(base)
    {:ok, quot} = Assets.from_denom(quot)
    # TODO 1: Fetch from actual trading data
    with {:ok, base_p} <- Rujira.Prices.get(String.upcase(base.symbol)),
         {:ok, quot_p} <- Rujira.Prices.get(String.upcase(quot.symbol)) do
      {:ok,
       %{
         last: trunc(base_p.price * 10 ** 12 / quot_p.price),
         last_usd: base_p.price,
         high: trunc(base_p.price * 1.3),
         low: trunc(base_p.price * 0.8),
         change: trunc(base_p.change * 1_000_000_000_000),
         volume: %{
           asset: quot,
           amount: 1_736_773_000_000
         }
       }}
    end
  end

  def account(%{address: address}, _, _) do
    {:ok, %{address: address, orders: nil, history: nil}}
  end

  def orders(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, orders} <- Fin.list_all_orders(address) do
        {:ok,
         %{
           page_info: %{
             start_cursor: <<>>,
             end_cursor: <<>>,
             has_previous_page: false,
             has_next_page: false
           },
           edges: Enum.map(orders, &%{cursor: <<>>, node: &1})
         }}
      end
    end)
  end

  def history(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, history} <- Fin.account_history(address) do
        {:ok,
         %{
           page_info: %{
             start_cursor: <<>>,
             end_cursor: <<>>,
             has_previous_page: false,
             has_next_page: false
           },
           edges: Enum.map(history, &%{cursor: <<>>, node: &1})
         }}
      end
    end)
  end

  def candles(%{address: address}, %{before: to, after: from, resolution: resolution}, _) do
    Helpers.async(fn ->
      {:ok,
       %{
         page_info: %{
           start_cursor: <<>>,
           end_cursor: <<>>,
           has_previous_page: false,
           has_next_page: false
         },
         edges: Enum.map(Fin.candles(address, from, to, resolution), &%{cursor: <<>>, node: &1})
       }}
    end)
  end
end
