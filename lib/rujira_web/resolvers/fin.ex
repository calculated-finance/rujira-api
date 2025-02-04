defmodule RujiraWeb.Resolvers.Fin do
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

  def trades(_, _, _),
    do:
      {:ok,
       %{
         page_info: %{
           start_cursor: <<>>,
           end_cursor: <<>>,
           has_previous_page: false,
           has_next_page: false
         },
         edges: []
       }}

  def summary(%{token_base: base, token_quote: quot}, _, _) do
    # TODO 1: Fetch from actual trading data
    asset = quot |> String.replace("-", ".") |> String.upcase() |> Assets.from_string()
    base = String.split(base, "-") |> Enum.at(1, base)
    quot = String.split(quot, "-") |> Enum.at(1, quot)

    with {:ok, base} <- Rujira.Prices.get(String.upcase(base)),
         {:ok, quot} <- Rujira.Prices.get(String.upcase(quot)) do
      {:ok,
       %{
         last: trunc(base.price * 10 ** 12 / quot.price),
         last_usd: base.price,
         high: trunc(base.price * 1.3),
         low: trunc(base.price * 0.8),
         change: trunc(base.change * 1_000_000_000_000),
         volume: %{
           asset: asset,
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
      with {:ok, candles} <- Fin.candles(address, to, from, resolution) do
        {:ok,
         %{
           page_info: %{
             start_cursor: <<>>,
             end_cursor: <<>>,
             has_previous_page: false,
             has_next_page: false
           },
           edges: Enum.map(candles, &%{cursor: <<>>, node: &1})
         }}
      end
    end)
  end
end
