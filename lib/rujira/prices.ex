defmodule Rujira.Prices do
  alias Rujira.Fin
  alias Rujira.Prices.Price
  use Memoize

  def get(symbols) when is_list(symbols) do
    symbols
    |> Task.async_stream(&{&1, get(&1)}, timeout: :infinity)
    |> Enum.reduce({:ok, %{}}, fn
      {:ok, {id, res}}, {:ok, agg} ->
        {:ok, Map.put(agg, id, res)}

      {:error, err}, _ ->
        {:error, err}

      _, {:error, err} ->
        {:error, err}
    end)
  end

  defmemo get(symbol), expires_in: 15_000 do
    fetch(symbol)
  end

  def price_from_id(id) do
    with {:ok, v} <- get(id) do
      # Ensure we have a consistent ID returned
      {:ok, %{v | id: id}}
    end
  end

  def fetch("RUJI"), do: fin_price("x/ruji")
  def fetch("AUTO"), do: fin_price("thor.auto")
  def fetch("LQDY"), do: fetch("MNTA")

  # For Asset ID notitation, we can explicitly request
  def fetch("THOR.RUNE"), do: fetch("RUNE")
  def fetch("THOR." <> _ = denom), do: fin_price(String.downcase(denom))
  def fetch("thor." <> _ = denom), do: fin_price(denom)

  # Secure assets: Retrieves the price from the base layer pools.
  def fetch("BTC-BTC"), do: tor_price("BTC.BTC")
  def fetch("ETH-ETH"), do: tor_price("ETH.ETH")
  def fetch("VTHOR"), do: tor_price("ETH.VTHOR-0X815C23ECA83261B6EC689B60CC4A58B54BC24D8D")

  # Use the batching GenServer for Coingecko requests
  def fetch(symbol) do
    with {:ok, id} <- __MODULE__.Coingecko.id(symbol),
         {:ok, %{change: change, price: price, mcap: mcap}} <- __MODULE__.Coingecko.price(id) do
      {:ok,
       %Price{
         id: symbol,
         source: :coingecko,
         change_day: change,
         current: price,
         mcap: mcap,
         timestamp: DateTime.utc_now()
       }}
    else
      {:error, _} = err -> err
    end
  end

  def normalize(price, decimal \\ 8)
      when is_number(price) and is_integer(decimal) and decimal >= 0 do
    trunc(price * 10 ** (12 - decimal))
  end

  def tor_price(id) do
    with {:ok, price} <- Thorchain.oracle_price(id) do
      {:ok, %Price{id: id, source: :tor, current: price, timestamp: DateTime.utc_now()}}
    else
      _ ->
        {:ok, nil}
    end
  end

  def fin_price(id) do
    with {:ok, pair} <- Fin.get_stable_pair(id),
         {:ok, %{book: book}} <- Fin.load_pair(pair) do
      {:ok,
       %Price{
         id: id,
         source: :fin,
         current: book.center,
         change_day:
           case Fin.get_summary(pair.address) do
             %{change: change} -> Decimal.to_float(change)
             nil -> nil
           end,
         timestamp: DateTime.utc_now()
       }}
    end
  end
end
