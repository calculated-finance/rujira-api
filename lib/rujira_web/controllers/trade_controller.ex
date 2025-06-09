defmodule RujiraWeb.TradeController do
  alias Rujira.Fin
  alias Rujira.Fin.Pair
  use RujiraWeb, :controller

  def tickers(conn, _) do
    with {:ok, pairs} <- Rujira.Fin.list_pairs(),
         {:ok, pairs} <- Rujira.Enum.reduce_while_ok(pairs, [], &Fin.load_pair(&1, 1)) do
      render(conn, "tickers.json", %{pairs: pairs, summaries: Rujira.Fin.get_summaries()})
    end
  end

  def orderbook(conn, %{"ticker_id" => ticker_id} = params) do
    with {:ok, pairs} <- Rujira.Fin.list_pairs(),
         %Pair{} = pair <- Enum.find(pairs, &(Fin.ticker_id!(&1) == ticker_id)),
         {depth, ""} <- Integer.parse(Map.get(params, "depth", "100")),
         {:ok, pair} <- Fin.load_pair(pair, round(depth / 2)) do
      render(conn, "orderbook.json", %{pair: pair})
    else
      nil -> put_status(conn, :not_found)
    end
  end

  def trades(conn, %{"ticker_id" => ticker_id} = params) do
    with {:ok, pairs} <- Rujira.Fin.list_pairs(),
         %Pair{} = pair <- Enum.find(pairs, &(Fin.ticker_id!(&1) == ticker_id)),
         {limit, ""} <- Integer.parse(Map.get(params, "limit", "100")) do
      render(conn, "trades.json", %{trades: Fin.list_trades(pair.address, limit, :desc)})
    else
      nil -> put_status(conn, :not_found)
    end
  end
end
