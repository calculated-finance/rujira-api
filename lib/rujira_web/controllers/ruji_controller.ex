defmodule RujiraWeb.RujiController do
  use RujiraWeb, :controller
  use Memoize
  @denom "x/ruji"

  def total_supply(conn, _) do
    json(conn, 100_000_000)
  end

  def circulating_supply(conn, _) do
    with start when is_binary(start) <- System.get_env("TOKEN_RELEASE_DATE"),
         {start, ""} <- Integer.parse(start) do
      now = DateTime.to_unix(DateTime.utc_now())
      duration = Decimal.new(4 * 365 * 24 * 60 * 60)

      vested =
        max(now - start, 0)
        |> Decimal.new()
        |> Decimal.div(duration)
        |> Decimal.mult(Decimal.new(25_500_000))

      json(conn, Decimal.new(74_500_000) |> Decimal.add(vested))
    else
      _ ->
        json(conn, Decimal.new(74_500_000))
    end
  end

  def holders(conn, _) do
    with {:ok, holders} <- Thorchain.get_holders(@denom) do
      render(conn, "holders.json", %{holders: holders})
    end
  end
end
