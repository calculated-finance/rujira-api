defmodule Rujira.CoingeckoMocks do
  import Tesla.Mock
  import ExUnit.Assertions

  @mock_body_price %{
    "tcy"     => %{"usd" => 42.0,     "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "bitcoin" => %{"usd" => 100_000.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "rune"    => %{"usd" => 100.0,    "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000}
  }

  @mock_body_search_by_id %{
    "RUNE" => %{"coins" => [%{"id" => "rune"}]}
  }

  @doc """
  Install a global Tesla mock for all Coingecko endpoints.
  """
  def mock_prices do
    mock_global(fn %Tesla.Env{url: url} = env ->
      %URI{path: path, query: query} = URI.parse(url)
      params = URI.decode_query(query || "")

      cond do
        path == "/api/v3/simple/price" ->
          %Tesla.Env{env | status: 200, body: @mock_body_price}

        path == "/api/v3/search" ->
          symbol = params["query"]
          body   = Map.get(@mock_body_search_by_id, symbol, %{"coins" => []})
          %Tesla.Env{env | status: 200, body: body}

        true ->
          flunk("unexpected HTTP call to #{url}")
      end
    end)
  end
end
