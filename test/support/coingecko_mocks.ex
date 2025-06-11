defmodule Rujira.CoingeckoMocks do
  import Tesla.Mock
  import ExUnit.Assertions

  @mock_body_price %{
    "tcy" => %{"usd" => 42.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "bitcoin" => %{"usd" => 100_000.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "thorchain" => %{"usd" => 100.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "nami-protocol" => %{"usd" => 100.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "mantadao" => %{"usd" => 100.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "usd-coin" => %{"usd" => 1.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "bifrost-bridged-bnb-bifrost" => %{"usd" => 230, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "bifrost-bridged-eth-bifrost" => %{"usd" => 1000, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
    "tether" => %{"usd" => 1.0, "usd_24h_change" => 1.23, "usd_market_cap" => 1_000_000},
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

      cond do
        path == "/api/v3/simple/price" ->
          %Tesla.Env{env | status: 200, body: @mock_body_price}

        path == "/api/v3/search" ->
          symbol = params["query"] |> String.downcase()

          case Enum.find(@coins_list, fn %{"symbol" => sym} ->
                 String.downcase(sym) == symbol
               end) do
            %{"id" => id} ->
              body = %{"coins" => [%{"id" => id}]}
              %Tesla.Env{env | status: 200, body: body}

            nil ->
              %Tesla.Env{env | status: 200, body: %{"coins" => []}}
          end

        true ->
          flunk("unexpected HTTP call to #{url}")
      end
    end)
  end
end
