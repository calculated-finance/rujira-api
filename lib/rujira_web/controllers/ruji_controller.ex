defmodule RujiraWeb.RujiController do
  use RujiraWeb, :controller
  use Memoize
  alias Cosmos.Bank.V1beta1.QueryDenomOwnersRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  import Cosmos.Bank.V1beta1.Query.Stub
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
        json(conn, Decimal.new(0))
    end
  end

  def holders(conn, _) do
    with {:ok, holders} <- get_holders() do
      render(conn, "holders.json", %{holders: holders})
    end
  end

  defmemop get_holders(), expires_in: 30 * 60 * 60 * 1000 do
    with {:ok, holders} <- page() do
      {:ok, holders |> Enum.sort_by(&Integer.parse(&1.balance.amount), :desc) |> Enum.take(100)}
    end
  end

  defp page(key \\ nil)

  defp page(nil) do
    with {:ok, %{denom_owners: denom_owners, pagination: %{next_key: next_key}}} <-
           Thorchain.Node.stub(
             &denom_owners/2,
             %QueryDenomOwnersRequest{denom: @denom}
           ),
         {:ok, next} <- page(next_key) do
      {:ok, Enum.concat(denom_owners, next)}
    end
  end

  defp page("") do
    {:ok, []}
  end

  defp page(key) do
    with {:ok, %{denom_owners: denom_owners, pagination: %{next_key: next_key}}} <-
           Thorchain.Node.stub(
             &denom_owners/2,
             %QueryDenomOwnersRequest{denom: @denom, pagination: %PageRequest{key: key}}
           ),
         {:ok, next} <- page(next_key) do
      {:ok, Enum.concat(denom_owners, next)}
    end
  end
end
