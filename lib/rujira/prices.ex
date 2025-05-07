defmodule Rujira.Prices do
  alias Rujira.Fin

  def get("AUTO"), do: {:ok, %{price: nil, change: nil}}
  def get("TCY"), do: {:ok, %{price: nil, change: nil}}
  def get("LQDY"), do: get("MNTA")

  # Switch Tokens or custom tokens: Retrieves the price from the applayer using the FIN pair with USDC.
  def get("x/demo"),
    do: Fin.book_price("sthor1df2x64qcyr2swrdgqtcjrxwny4vp0n622hnltr7k0cqdgw7t4szshcxvkj")

  # Secure assets: Retrieves the price from the base layer pools.
  def get("BTC-BTC"), do: secure_asset_price("BTC.BTC")
  def get("ETH-ETH"), do: secure_asset_price("ETH.ETH")

  def get("RUJI") do
    with {:ok, kuji} <- get("KUJI") do
      {:ok, %{price: Decimal.div(kuji.price, Decimal.from_float(0.37)), change: kuji.change}}
    end
  end

  def get(symbols) when is_list(symbols) do
    map =
      Enum.reduce(symbols, [], fn v, a ->
        case __MODULE__.Coingecko.id(v) do
          {:ok, id} ->
            [{v, id} | a]

          _ ->
            a
        end
      end)

    with {:ok, res} <- __MODULE__.Coingecko.prices(Enum.map(map, &elem(&1, 1))) do
      {:ok,
       map
       |> Enum.map(fn {sym, id} ->
         {sym, Map.get(res, id)}
       end)
       |> Map.new()}
    end
  end

  def get(symbol) do
    with {:ok, id} <- __MODULE__.Coingecko.id(symbol),
         {:ok, res} <- __MODULE__.Coingecko.price(id) do
      {:ok, res}
    end
  end

  def normalize(price, decimal \\ 8)
      when is_number(price) and is_integer(decimal) and decimal >= 0 do
    trunc(price * 10 ** (12 - decimal))
  end

  def secure_asset_price(id) do
    with {:ok, %{asset_tor_price: price}} <- Thorchain.pool_from_id(id) do
      {:ok, %{price: normalize(price), change: 0}}
    end
  end
end
