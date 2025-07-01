defmodule Rujira.CoingeckoMocks do
  @moduledoc false
  import Tesla.Mock
  import ExUnit.Assertions

  @mock_body_price %{
    "avalanche-2" => %{"usd" => 42.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "kujira" => %{"usd" => 42.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "tcy" => %{"usd" => 42.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "bitcoin" => %{"usd" => 100_000.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "cosmos" => %{"usd" => 100.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "thorchain" => %{"usd" => 100.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "nami-protocol" => %{"usd" => 100.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "mantadao" => %{"usd" => 100.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "usd-coin" => %{"usd" => 1.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "binance-peg-dogecoin" => %{
      "usd" => 1.0,
      "usd_24h_change" => 1.23,
      "usd_market_cap" => 1_000_000
    },
    "binance-peg-bitcoin-cash" => %{
      "usd" => 1.0,
      "usd_24h_change" => 1.23,
      "usd_market_cap" => 1_000_000
    },
    "coinbase-wrapped-btc" => %{
      "usd" => 1.0,
      "usd_24h_change" => 1.23,
      "usd_market_cap" => 1_000_000
    },
    "binance-peg-xrp" => %{"usd" => 1.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "binance-peg-litecoin" => %{
      "usd" => 1.0,
      "usd_24h_change" => 1.23,
      "usd_market_cap" => 1_000_000
    },
    "bifrost-bridged-bnb-bifrost" => %{
      "usd" => 230,
      "usd_24h_change" => 1.23,
      "usd_market_cap" => 1_000_000
    },
    "bifrost-bridged-eth-bifrost" => %{
      "usd" => 1000,
      "usd_24h_change" => 1.23,
      "usd_market_cap" => 1_000_000
    },
    "tether" => %{"usd" => 1.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000}
  }

  # fetch from https://api.coingecko.com/api/v3/coins/list
  @coins_list File.read!("test/fixtures/coin_list") |> Jason.decode!()

  @doc """
  Install a global Tesla mock for all Coingecko endpoints.
  """
  def mock_prices do
    mock_global(fn %Tesla.Env{url: url} = env ->
      %URI{path: path, query: query} = URI.parse(url)
      params = URI.decode_query(query || "")

      case path do
        "/api/v3/simple/price" ->
          mock_simple_price(env)

        "/api/v3/search" ->
          mock_search(env, params)

        _ ->
          flunk("unexpected HTTP call to #{url}")
      end
    end)
  end

  defp mock_simple_price(env) do
    %Tesla.Env{env | status: 200, body: @mock_body_price}
  end

  defp mock_search(env, %{"query" => query}) do
    symbol = String.downcase(query)

    case Enum.find(@coins_list, fn %{"symbol" => sym} ->
           String.downcase(sym) == symbol
         end) do
      %{"id" => id} ->
        %Tesla.Env{env | status: 200, body: %{"coins" => [%{"id" => id}]}}

      nil ->
        %Tesla.Env{env | status: 200, body: %{"coins" => []}}
    end
  end
end
