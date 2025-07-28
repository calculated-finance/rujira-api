defmodule Rujira.Perps.Account do
  @moduledoc """
  Rujira Perps Account.
  """
  alias Rujira.Perps.Pool

  defstruct [
    :id,
    :pool,
    :account,
    :lp_shares,
    :lp_value,
    :xlp_shares,
    :xlp_value,
    :available_yield_lp,
    :available_yield_xlp,
    :liquidity_cooldown
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          pool: Pool.t(),
          account: String.t(),
          lp_shares: non_neg_integer(),
          lp_value: non_neg_integer(),
          xlp_shares: non_neg_integer(),
          xlp_value: non_neg_integer(),
          available_yield_lp: non_neg_integer(),
          available_yield_xlp: non_neg_integer(),
          liquidity_cooldown: map()
        }

  def from_query(pool, account, %{
        "lp_amount" => lp_amount,
        "lp_collateral" => lp_collateral,
        "xlp_amount" => xlp_amount,
        "xlp_collateral" => xlp_collateral,
        "available_yield_lp" => available_yield_lp,
        "available_yield_xlp" => available_yield_xlp,
        "liquidity_cooldown" => liquidity_cooldown
      }) do
    with {lp_shares, ""} <- Decimal.parse(lp_amount),
         {lp_value, ""} <- Decimal.parse(lp_collateral),
         {xlp_shares, ""} <- Decimal.parse(xlp_amount),
         {xlp_value, ""} <- Decimal.parse(xlp_collateral),
         {available_yield_lp, ""} <- Decimal.parse(available_yield_lp),
         {available_yield_xlp, ""} <- Decimal.parse(available_yield_xlp) do
      liquidity_cooldown = parse_liquidity_cooldown(liquidity_cooldown)

      {:ok,
       %__MODULE__{
         id: "#{account}/#{pool.address}",
         pool: pool,
         account: account,
         lp_shares: normalize(lp_shares),
         lp_value: normalize(lp_value),
         xlp_shares: normalize(xlp_shares),
         xlp_value: normalize(xlp_value),
         available_yield_lp: normalize(available_yield_lp),
         available_yield_xlp: normalize(available_yield_xlp),
         liquidity_cooldown: liquidity_cooldown
       }}
    end
  end

  defp parse_liquidity_cooldown(%{"at" => at, "seconds" => seconds}) do
    with {at, ""} <- Integer.parse(at),
         {:ok, at_time} <- DateTime.from_unix(at, :nanosecond) do
      %{
        start_at: DateTime.add(at_time, -seconds, :second),
        end_at: at_time
      }
    end
  end

  defp parse_liquidity_cooldown(nil), do: nil

  defp normalize(decimal),
    do: Decimal.mult(decimal, 100_000_000) |> Decimal.round() |> Decimal.to_integer()
end
