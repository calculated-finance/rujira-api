defmodule Rujira.Prices.Coingecko do
  @moduledoc """
  Fetches and caches cryptocurrency price data from the CoinGecko API.
  """
  use Memoize
  use GenServer
  require Logger

  @interval 60_000

  @ids [
    "bitcoin",
    "kujira",
    "aave",
    "dai",
    "defipulse-index",
    "chainflip",
    "shapeshift-fox-token",
    "gemini-dollar",
    "chainlink",
    "ripple-usd",
    "nami-protocol",
    "craze",
    "havven",
    "tcy",
    "thorwallet",
    "thorswap",
    "usd-coin",
    "paxos-standard",
    "tether",
    "wrapped-bitcoin",
    "winkhub",
    "xdefi",
    "thorstarter",
    "yearn-finance",
    "thorchain",
    "mantadao",
    "base-baboon",
    "unstake-fi",
    "fuzion"
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_) do
    send(self(), :fetch)
    {:ok, %{prices: %{}}}
  end

  @impl true
  def handle_call({:get_price, id}, _, %{prices: prices} = state) do
    case Map.get(prices, id) do
      nil -> {:reply, {:ok, nil}, state}
      price -> {:reply, {:ok, price}, state}
    end
  end

  @impl true
  def handle_info(:fetch, state) do
    prices =
      case prices(ids()) do
        {:ok, prices} -> prices
        _ -> state.prices
      end

    Process.send_after(self(), :fetch, @interval)
    {:noreply, %{state | prices: prices}}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Unhandled message in Coingecko GenServer: #{inspect(msg)}")
    {:noreply, state}
  end

  def price(id) do
    case GenServer.call(__MODULE__, {:get_price, id}, 10_000) do
      {:ok, price} -> {:ok, price}
      {:error, _} = err -> err
    end
  end

  def id("AUTO"), do: {:error, :not_found}
  def id("BTC"), do: {:ok, "bitcoin"}
  def id("RKUJI"), do: {:ok, "kujira"}
  def id("rKUJI"), do: {:ok, "kujira"}
  def id("KUJI"), do: {:ok, "kujira"}
  def id("AAVE"), do: {:ok, "aave"}
  def id("DAI"), do: {:ok, "dai"}
  def id("DPI"), do: {:ok, "defipulse-index"}
  def id("FLIP"), do: {:ok, "chainflip"}
  def id("FOX"), do: {:ok, "shapeshift-fox-token"}
  def id("GUSD"), do: {:ok, "gemini-dollar"}
  def id("LINK"), do: {:ok, "chainlink"}
  def id("LUSD"), do: {:ok, "ripple-usd"}
  def id("NAMI"), do: {:ok, "nami-protocol"}
  def id("RAZE"), do: {:ok, "craze"}
  def id("SNX"), do: {:ok, "havven"}
  def id("TCY"), do: {:ok, "tcy"}
  def id("TGT"), do: {:ok, "thorwallet"}
  def id("THOR"), do: {:ok, "thorswap"}
  def id("USDC" <> _), do: {:ok, "usd-coin"}
  def id("USDP"), do: {:ok, "paxos-standard"}
  def id("USDT" <> _), do: {:ok, "tether"}
  def id("WBTC"), do: {:ok, "wrapped-bitcoin"}
  def id("WINK"), do: {:ok, "winkhub"}
  def id("XDEFI"), do: {:ok, "xdefi"}
  def id("XRUNE"), do: {:ok, "thorstarter"}
  def id("YFI"), do: {:ok, "yearn-finance"}
  def id("CBBTC" <> _), do: {:ok, "coinbase-wrapped-btc"}
  def id(symbol), do: lookup_id(symbol)

  def ids(symbols) do
    Enum.reduce(symbols, {:ok, []}, fn
      _, {:error, err} ->
        {:error, err}

      el, {:ok, acc} ->
        case id(el) do
          {:ok, id} -> {:ok, [id | acc]}
          err -> err
        end
    end)
  end

  def prices(ids) do
    case proxy("v3/simple/price", %{
           "ids" => Enum.join(Enum.uniq(ids), ","),
           "vs_currencies" => "usd",
           "include_24hr_change" => "true",
           "include_market_cap" => "true"
         }) do
      {:ok, %{body: %{} = res}} ->
        {:ok,
         res
         |> Enum.map(fn
           {k, %{"usd" => price, "usd_24h_change" => change, "usd_market_cap" => mcap}} ->
             {:ok, price} = Decimal.cast(price)

             {k, %{price: price, change: change, mcap: floor(mcap)}}

           {k, %{}} ->
             {k, %{price: nil, change: nil, mcap: nil}}
         end)
         |> Map.new()}

      nil ->
        {:error, "error fetching #{ids} price"}

      str when is_binary(str) ->
        {:error, "error fetching #{ids} price: #{str}"}

      {:error, %{reason: reason}} ->
        {:error, reason}

      err ->
        err
    end
  end

  defmemop lookup_id(symbol) do
    case proxy("v3/search", %{"query" => symbol}) do
      {:ok, %{body: %{"coins" => [%{"id" => id} | _]}}} ->
        {:ok, id}

      {:ok, %{body: %{"coins" => []}}} ->
        {:error, "no coingecko id found for #{symbol}"}

      err ->
        err
    end
  end

  defmemop ids() do
    with {:ok, pools} <- Thorchain.pools(),
         {:ok, ids} <-
           Rujira.Enum.reduce_async_while_ok(pools, fn %{asset: asset} -> id(asset.symbol) end) do
      ids
      |> Enum.concat(@ids)
      |> Enum.uniq()
    end
  end

  defmemop proxy(path, params), expires_in: 15_000 do
    config = Application.get_env(:rujira, __MODULE__)

    params = Map.put(params, "x_cg_pro_api_key", config[:cg_key])
    uri = %URI{path: "https://pro-api.coingecko.com/api/#{path}", query: URI.encode_query(params)}

    [Tesla.Middleware.JSON, {Tesla.Middleware.Timeout, timeout: 10_000}]
    |> Tesla.client()
    |> Tesla.get(URI.to_string(uri))
  end
end
