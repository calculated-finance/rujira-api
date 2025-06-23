defmodule RujiraWeb.Resolvers.Fin do
  @moduledoc """
  Handles GraphQL resolution for Fin Protocol-related queries.
  """
  alias Absinthe.Relay
  alias Absinthe.Resolution.Helpers
  alias Rujira.Assets
  alias Rujira.Fin
  alias Rujira.Fin.Summary
  alias Rujira.Repo

  def node(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, pair} <- Rujira.Fin.get_pair(address) do
        Rujira.Fin.load_pair(pair)
      end
    end)
  end

  def resolver(_, _, _) do
    Helpers.async(fn ->
      Rujira.Fin.list_pairs()
    end)
  end

  def get_pair(%{pair: pair}, _, _), do: Fin.get_pair(pair)

  def book(%{book: :not_loaded} = pair, _, _) do
    with {:ok, %{book: book}} <- Rujira.Fin.load_pair(pair) do
      {:ok, Map.put(book, :contract, pair.address)}
    end
  end

  def book(%{address: address, book: book}, _, _), do: {:ok, Map.put(book, :contract, address)}

  def book_pair(%{contract: contract}, _, _), do: Rujira.Fin.get_pair(contract)

  def trades(%{address: address}, args, _) do
    address
    |> Fin.list_trades_query()
    |> Relay.Connection.from_query(&Repo.all/1, args)
  end

  def summary(%{address: address, token_quote: token_quote}, _, _) do
    with %Summary{} = summary <- Rujira.Fin.get_summary(address),
         {:ok, volume_asset} <- Assets.from_denom(token_quote),
         {:ok, %{current: price}} <- Rujira.Prices.get(String.upcase(volume_asset.ticker)) do
      {:ok,
       %{
         summary
         | last_usd: Decimal.mult(price, summary.last),
           volume: %{
             asset: volume_asset,
             amount: summary.volume
           }
       }}
    else
      nil -> {:ok, nil}
      {:error, err} -> {:error, err}
    end
  end

  def account(%{address: address}, _, _) do
    {:ok, %{address: address, orders: nil, history: nil}}
  end

  def order_edge(order, args, _) do
    # For `trade` events, the owner and contract comes from args, otherwise it's in order
    %{side: side, price: price, owner: owner, contract: contract} = Map.merge(order, args)

    with {:ok, pair} <- Fin.get_pair(contract),
         {:ok, order} <- Fin.load_order(pair, side, price, owner) do
      {:ok, %{cursor: order.id, node: order}}
    end
  end

  @spec orders(%{:address => any(), optional(any()) => any()}, any(), any()) ::
          {:middleware, Absinthe.Middleware.Async, {any(), any()}}
  def orders(%{address: address}, args, _) do
    Helpers.async(fn ->
      with {:ok, orders} <- Fin.list_all_orders(address) do
        Relay.Connection.from_list(orders, args)
      end
    end)
  end

  def history(%{address: address}, args, _) do
    Helpers.async(fn ->
      with {:ok, history} <- Fin.list_account_history(address) do
        Relay.Connection.from_list(history, args)
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
