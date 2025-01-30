defmodule Rujira.Prices do
  def get("RUJI") do
    with {:ok, kuji} <- get("KUJI") do
      {:ok, %{price: trunc(kuji.price / 0.37), change: kuji.change}}
    end
  end

  def get(symbols) when is_list(symbols) do
    with {:ok, ids} <- __MODULE__.Coingecko.ids(symbols),
         {:ok, res} <- __MODULE__.Coingecko.prices(ids) do
      {:ok,
       res
       |> Enum.zip(symbols)
       |> Enum.map(fn {{_id, v}, sym} -> {sym, normalize(v)} end)
       |> Map.new()}
    end
  end

  def get(symbol) do
    with {:ok, id} <- __MODULE__.Coingecko.id(symbol),
         {:ok, res} <- __MODULE__.Coingecko.price(id) do
      {:ok, normalize(res)}
    end
  end

  defp normalize(%{price: price, change: change}) do
    %{price: trunc(price * 10 ** 12), change: change}
  end
end
