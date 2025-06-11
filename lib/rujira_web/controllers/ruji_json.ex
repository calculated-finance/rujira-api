defmodule RujiraWeb.RujiJSON do
  def render("holders.json", %{holders: holders}) do
    for(holder <- holders, do: data(holder))
  end

  def data(%{address: address, balance: balance}) do
    %{address: address, amount: amount(balance.amount)}
  end

  defp amount(v), do: Decimal.div(Decimal.new(v), Decimal.new(100_000_000))
end
