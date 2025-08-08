defmodule Rujira.Pilot.Sale do
  @moduledoc """
  This module Parses the sale data from the Keiko contract into a the correct Rujira Pilot struct
  """
  alias Rujira.Pilot
  alias Rujira.Pilot.BidPools

  defstruct [
    :address,
    :bid_denom,
    :bid_pools,
    :bid_threshold,
    :closes,
    :sale_amount,
    :deposit,
    :fee_amount,
    :max_premium,
    :opens,
    :price,
    :raise_amount,
    :waiting_period,

    # Calculated fields
    :completion_percentage,
    :duration,
    :avg_price
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          bid_denom: String.t(),
          bid_pools: BidPools.t(),
          bid_threshold: non_neg_integer(),
          closes: DateTime.t(),
          sale_amount: non_neg_integer(),
          deposit: map(),
          fee_amount: non_neg_integer(),
          max_premium: non_neg_integer(),
          opens: DateTime.t(),
          price: Decimal.t(),
          raise_amount: non_neg_integer(),
          waiting_period: non_neg_integer()
        }

  def from_query(
        status,
        sale_amount,
        %{
          "bid_pools_snapshot" => bid_pools_snapshot,
          "contract_address" => contract_address,
          "deposit" => deposit,
          "fee_amount" => fee_amount,
          "pilot" => %{
            "bid_denom" => bid_denom,
            "bid_threshold" => bid_threshold,
            "closes" => closes,
            "max_premium" => max_premium,
            "opens" => opens,
            "price" => price,
            "waiting_period" => waiting_period
          },
          "raise_amount" => raise_amount
        }
      ) do
    with {:ok, deposit} <- parse_deposit(deposit),
         {:ok, bid_threshold} <- parse_optional_integer(bid_threshold),
         {:ok, fee_amount} <- parse_optional_integer(fee_amount),
         {price, ""} <- Decimal.parse(price),
         {:ok, raise_amount} <- parse_optional_integer(raise_amount),
         {opens, ""} <- Integer.parse(opens),
         {:ok, opens} <- DateTime.from_unix(opens, :nanosecond),
         {closes, ""} <- Integer.parse(closes),
         {:ok, closes} <- DateTime.from_unix(closes, :nanosecond) do
      duration = DateTime.diff(closes, opens)

      {:ok,
       %__MODULE__{
         address: contract_address,
         bid_denom: bid_denom,
         bid_threshold: bid_threshold,
         closes: closes,
         sale_amount: sale_amount,
         deposit: deposit,
         fee_amount: fee_amount,
         max_premium: max_premium,
         opens: opens,
         price: price,
         raise_amount: raise_amount,
         waiting_period: waiting_period,
         duration: duration,
         completion_percentage: 0,
         avg_price: 0
       }
       |> parse_bid_pools(bid_pools_snapshot, status)
       |> calculate_stats()}
    end
  end

  defp parse_bid_pools(sale, %{"pools" => pools}, :completed) do
    with {:ok, pools} <- Rujira.Enum.reduce_while_ok(pools, &Pilot.Pool.from_query/1) do
      %{sale | bid_pools: %BidPools{id: sale.address, pools: pools}}
    end
  end

  defp parse_bid_pools(sale, _, _) do
    case Pilot.pools(sale, nil, nil) do
      {:ok, pools} -> %{sale | bid_pools: pools}
      # <-- keep everything as-is
      _error -> sale
    end
  end

  defp parse_deposit(%{"amount" => amount, "denom" => denom}) do
    with {amount, ""} <- Integer.parse(amount) do
      {:ok, %{amount: amount, denom: denom}}
    end
  end

  defp parse_deposit(nil), do: {:ok, nil}

  defp parse_optional_integer(nil), do: {:ok, nil}

  defp parse_optional_integer(val) do
    case Integer.parse(val) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  defp calculate_stats(sale) do
    if sale.bid_pools do
      {allocated_tokens, total_deposits} =
        Enum.reduce(sale.bid_pools.pools, {Decimal.new(0), Decimal.new(0)}, fn pool, {acc, t} ->
          total = Decimal.new(pool.total)
          allocated = checked_div(total, pool.rate)
          {Decimal.add(acc, allocated), Decimal.add(t, total)}
        end)

      completion_percentage = checked_div(allocated_tokens, sale.sale_amount)
      avg_price = checked_div(total_deposits, allocated_tokens)

      %{
        sale
        | completion_percentage: completion_percentage,
          avg_price: avg_price
      }
    else
      sale
    end
  end

  defp checked_div(num, denom) do
    if denom == Decimal.new(0) do
      Decimal.new(0)
    else
      Decimal.div(num, denom)
    end
  end
end
