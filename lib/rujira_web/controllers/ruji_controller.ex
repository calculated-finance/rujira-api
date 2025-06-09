defmodule RujiraWeb.RujiController do
  use RujiraWeb, :controller

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
        |> Decimal.div(Decimal.new(duration))
        |> then(&Decimal.sub(Decimal.new(1), &1))
        |> Decimal.mult(Decimal.new(25_500_000))

      json(conn, Decimal.new(74_500_000) |> Decimal.add(vested))
    else
      _ ->
        json(conn, Decimal.new(0))
    end
  end
end
