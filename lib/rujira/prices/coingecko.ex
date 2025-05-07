defmodule Rujira.Prices.Coingecko do
  use Memoize

  def id("AUTO"), do: {:error, :not_found}
  def id("TCY"), do: {:error, :not_found}
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
  def id("TGT"), do: {:ok, "thorwallet"}
  def id("THOR"), do: {:ok, "thorswap"}
  def id("USDC"), do: {:ok, "usd-coin"}
  def id("USDP"), do: {:ok, "paxos-standard"}
  def id("USDT"), do: {:ok, "tether"}
  def id("WBTC"), do: {:ok, "wrapped-bitcoin"}
  def id("WINK"), do: {:ok, "winkhub"}
  def id("XDEFI"), do: {:ok, "xdefi"}
  def id("XRUNE"), do: {:ok, "thorstarter"}
  def id("YFI"), do: {:ok, "yearn-finance"}
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

  def price(id) do
    with {:ok, %{body: res}} <-
           proxy("v3/simple/price", %{
             "ids" => id,
             "vs_currencies" => "usd",
             "include_24hr_change" => "true"
           }),
         %{"usd" => price, "usd_24h_change" => change} <- Map.get(res, id) do
      {:ok, price} = Decimal.cast(price)
      {:ok, %{price: price, change: change}}
    else
      nil -> {:error, "error fetching #{id} price"}
      err -> err
    end
  end

  def prices(ids) do
    with {:ok, %{body: res}} <-
           proxy("v3/simple/price", %{
             "ids" => Enum.join(ids, ","),
             "vs_currencies" => "usd",
             "include_24hr_change" => "true"
           }) do
      {:ok,
       res
       |> Enum.map(fn
         {k, %{"usd" => price, "usd_24h_change" => change}} ->
           {:ok, price} = Decimal.cast(price)
           {k, %{price: price, change: change}}

         {k, %{}} ->
           {k, %{price: nil, change: nil}}
       end)
       |> Map.new()}
    else
      nil -> {:error, "error fetching #{ids} price"}
      err -> err
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

  defmemop proxy(path, params), expires_in: 15000 do
    config = Application.get_env(:rujira, __MODULE__)

    params = Map.put(params, "x_cg_pro_api_key", config[:cg_key])
    uri = %URI{path: "https://pro-api.coingecko.com/api/#{path}", query: URI.encode_query(params)}

    [Tesla.Middleware.JSON]
    |> Tesla.client()
    |> Tesla.get(URI.to_string(uri))
  end
end
