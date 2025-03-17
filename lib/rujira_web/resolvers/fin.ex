defmodule RujiraWeb.Resolvers.Fin do
  alias Rujira.Repo
  alias Absinthe.Relay
  alias Rujira.Fin.Trades.Trade
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

  def trades(%{address: address}, args, _) do
    address
    |> Fin.list_trades_query()
    |> Relay.Connection.from_query(&Repo.all/1, args)
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
      with {:ok, history} <- Fin.list_account_history(address) do
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

  def candles(%{address: address}, %{after: from, resolution: resolution, before: to}, _) do
    Helpers.async(fn ->
      {:ok,
       Fin.range_candles(address, from, to, resolution)
       |> Enum.reverse()
       |> insert_candle_nodes()}
    end)
  end

  defp insert_candle_nodes(
         candles,
         agg \\ %{
           page_info: %{
             start_cursor: <<>>,
             end_cursor: <<>>,
             has_previous_page: false,
             has_next_page: false
           },
           edges: []
         }
       )

  defp insert_candle_nodes([c], %{page_info: page_info} = agg) do
    insert_candle_nodes([], %{
      agg
      | edges: [%{cursor: c.bin, node: c} | agg.edges],
        page_info: %{page_info | start_cursor: c.bin}
    })
  end

  defp insert_candle_nodes([c | rest], %{page_info: page_info} = agg) do
    insert_candle_nodes(rest, %{
      agg
      | edges: [%{cursor: c.bin, node: c} | agg.edges],
        page_info: %{page_info | start_cursor: c.bin, end_cursor: c.bin}
    })
  end

  defp insert_candle_nodes([], agg), do: agg
end
