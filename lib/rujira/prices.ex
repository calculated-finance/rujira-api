defmodule Rujira.Prices do
  def get("RUJI") do
    with {:ok, kuji} <- get("KUJI") do
      {:ok, %{price: trunc(kuji.price / 0.37), change: kuji.change}}
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
      |> Enum.sort_by(&elem(&1, 1))

    with {:ok, res} <- __MODULE__.Coingecko.prices(Enum.map(map, &elem(&1, 1))) do
      {:ok,
       res
       |> Enum.zip(map)
       |> Enum.map(fn {{_id, res}, {sym, _}} -> {sym, normalize(res)} end)
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
