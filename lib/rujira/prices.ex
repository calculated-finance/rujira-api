defmodule Rujira.Prices do
  def get(symbol) do
    with {:ok, id} <- __MODULE__.Coingecko.id(symbol),
         {:ok, %{price: price, change: change}} <- __MODULE__.Coingecko.price(id) do
      {:ok, %{price: trunc(price * 10 ** 12), change: change}}
    end
  end
end
