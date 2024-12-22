defmodule RujiraWeb.Resolvers.Fin do
  alias Rujira.Fin
  alias Absinthe.Resolution.Helpers

  def node(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, pair} <- Rujira.Fin.get_pair(address) do
        {:ok, put_id(pair)}
      end
    end)
  end

  def resolver(_, _, _) do
    Helpers.async(fn ->
      with {:ok, pairs} <- Rujira.Fin.list_pairs() do
        {:ok, Enum.map(pairs, &put_id/1)}
      end
    end)
  end

  def summary(%{token_base: base, token_quote: quot}, _, _) do
    # TODO 1: Fetch from actual trading data
    asset = quot |> String.replace("-", ".") |> String.upcase()
    # TODO 2: we should be passing around the Layer 1 Asset notation here, not the x/bank denom
    base = String.split(base, "-") |> Enum.at(1, base)
    quot = String.split(quot, "-") |> Enum.at(1, quot)

    with {:ok, base} <- Rujira.Prices.get(String.upcase(base)),
         {:ok, quot} <- Rujira.Prices.get(String.upcase(quot)) do
      {:ok,
       %{
         last: base.price,
         last_usd: trunc(base.price / quot.price) * 10 ** 12,
         high: trunc(base.price * 1.3),
         low: trunc(base.price * 0.8),
         change: trunc(base.change * 1_000_000_000_000),
         volume: %{
           asset: asset,
           amount: 1_736_773_000_000_000_000_000_000
         }
       }}
    end
  end

  def account(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, orders} <- Fin.list_all_orders(address),
           {:ok, history} <- Fin.account_history(address) do
        {:ok, %{orders: orders, history: history}}
      end
    end)
  end

  def candles(%{address: address}, %{to: to, from: from, resolution: resolution}, _) do
    Helpers.async(fn ->
      with {:ok, candles} <- Fin.candles(address, to, from, resolution) do
        {:ok, candles}
      end
    end)
  end

  defp put_id(%{address: address} = pair) do
    %{pair | id: RujiraWeb.Resolvers.Node.encode_id(:contract, :fin, address)}
  end
end
