defmodule Rujira.Prices do
  def get("LQDY"), do: get("MNTA")

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

    with {:ok, res} <- __MODULE__.Coingecko.prices(Enum.map(map, &elem(&1, 1))) do
      {:ok,
       map
       |> Enum.map(fn {sym, id} ->
         {sym, normalize(Map.get(res, id))}
       end)
       |> Map.new()}
    end
  end

  def get(symbol) do
    with {:ok, id} <- __MODULE__.Coingecko.id(symbol),
         {:ok, res} <- __MODULE__.Coingecko.price(id) do
      {:ok, normalize(res)}
    end
  end

  def normalize(%{price: nil, change: nil}) do
    %{price: nil, change: nil}
  end

  def normalize(%{price: price, change: change}) do
    %{price: trunc(price * 10 ** 12), change: change}
  end

  def normalize(price, decimal \\ 8)
      when is_number(price) and is_integer(decimal) and decimal >= 0 do
    trunc(price * 10 ** (12 - decimal))
  end
end
