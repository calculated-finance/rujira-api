defmodule RujiraWeb.TradeController do
  alias Rujira.Fin
  alias Rujira.Fin.Pair
  use RujiraWeb, :controller

  def tickers(conn, _) do
    with {:ok, pairs} <- Rujira.Fin.list_pairs() do
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

  # def tickers(conn, _) do
  #   tickers = Kujira.FIN.tickers()

  #   conn
  #   |> put_resp_header("cache-control", "max-age=30")
  #   |> render("tickers.json", %{
  #     timestamp: DateTime.utc_now() |> DateTime.to_unix(:millisecond),
  #     tickers: tickers
  #   })
  # end

  # def orderbook(conn, %{"ticker_id" => ticker_id} = params) do
  #   depth = params |> Map.get("depth", "10") |> String.to_integer()

  #   d =
  #     case depth do
  #       0 -> 10000
  #       x -> x
  #     end

  #   with [b, q] <- String.split(ticker_id, "_"),
  #        b = Kujira.Denom.symbol(String.downcase(b)),
  #        q = Kujira.Denom.symbol(String.downcase(q)),
  #        {:ok, orderbook} <- Kujira.FIN.orderbook(b, q, d) do
  #     render(conn, "orderbook.json", %{
  #       ticker_id: ticker_id,
  #       timestamp: DateTime.utc_now() |> DateTime.to_unix(:millisecond),
  #       orderbook: orderbook
  #     })
  #   else
  #     [_] -> {:error, :invalid_ticker}
  #     e -> e
  #   end
  # end

  # def api(conn, %{"path" => path} = params) do
  #   with {:ok, %{body: body}} <-
  #          Kujira.Coingecko.proxy(Enum.join(path, "/"), Map.drop(params, ["path"])) do
  #     json(conn, body)
  #   end
  # end
end
