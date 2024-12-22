defmodule Rujira.Prices do
  def get("RUJI") do
    with {:ok, kuji} <- get("KUJI") do
      {:ok, %{price: trunc(kuji.price / 0.37), change: kuji.change}}
    end
  end

  def get(symbol) do
    with {:ok, id} <- __MODULE__.Coingecko.id(symbol),
         {:ok, %{price: price, change: change}} <- __MODULE__.Coingecko.price(id) do
      {:ok, %{price: trunc(price * 10 ** 12), change: change}}
    end
  end
end
