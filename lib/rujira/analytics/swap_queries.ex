defmodule Rujira.Analytics.SwapQueries do
  @moduledoc """
  This module defines queries for aggregating swap data with various metrics.

  It creates several Common Table Expressions (CTEs) to compute:
    - Unique swap users per bin.
    - Volume breakdown by asset.
    - Volume breakdown by chain.
    - Total volume per bin.

  The main `snapshots/4` query uses these CTEs and aggregates the swap data,
  computing sums, ratios, and moving averages across bins.
  """

  import Ecto.Query
  alias Thorchain.Swaps.Swap
  alias Thorchain.Swaps
  alias Rujira.Resolution

  # Returns a base query filtering swaps by a given time range and affiliate.

  # It applies the following filters:
  #   - Timestamp is between `from` and `to`.
  #   - Affiliate is not nil and equals the given `affiliate`.
  # Then, it sorts the results in descending order.
  defp base_query(from, to, affiliate) do
    Swap
    |> where(
      [s],
      s.timestamp >= ^from and s.timestamp <= ^to and
        not is_nil(s.affiliate) and s.affiliate == ^affiliate
    )
    |> Swaps.sort(:desc)
  end

  @doc """
  Aggregates swap data and computes various metrics for snapshots.

  It:
    - Adjusts the start time using `Resolution.shift_from_back/3`.
    - Attaches several CTEs for unique users, volume by asset, volume by chain, and total volume.
    - Joins the CTEs with the main aggregated query using the bin identifier.
    - Computes aggregated metrics (swaps count, fees, volume, etc.) per bin.
    - Applies window functions to compute moving averages over a defined period.

  The final result contains one row per bin with aggregated data and moving averages.
  """
  def snapshots(from, to, resolution, period) do
    with shifted_from <- Resolution.shift_from_back(from, period, resolution) do
      unique_users = unique_users_cte(shifted_from, to, "rj")
      volume_by_asset = volume_by_asset_cte(shifted_from, to, "rj")
      volume_by_chain = volume_by_chain_cte(shifted_from, to, "rj")
      total_volume = total_volume_cte(from, to)

      # Build the main aggregated query:
      # 1. Start with the base query filtered by time and affiliate.
      # 2. Convert to a subquery and apply resolution range adjustments.
      # 3. Join the "bins" table (right join) to partition the data into bins.
      # 4. Attach the additional CTEs via with_cte/3.
      # 5. Left join each CTE on the common bin (b.min) value.
      # 6. Select aggregated metrics for swaps, fees, volume, and data from the CTEs.
      base_query(shifted_from, to, "rj")
      |> subquery()
      |> Resolution.with_range(shifted_from, to, resolution)
      |> join(:right, [s], b in "bins", on: s.timestamp >= b.min and s.timestamp < b.max)
      |> with_cte("unique_users", as: ^unique_users)
      |> with_cte("volume_by_asset", as: ^volume_by_asset)
      |> with_cte("volume_by_chain", as: ^volume_by_chain)
      |> with_cte("total_volume", as: ^total_volume)
      |> join(:left, [s, b], u in "unique_users", on: u.bin == b.min)
      |> join(:left, [s, b, u], a in "volume_by_asset", on: a.bin == b.min)
      |> join(:left, [s, b, u, a], c in "volume_by_chain", on: c.bin == b.min)
      |> join(:left, [s, b, u, a, c], v in "total_volume", on: v.bin == b.min)
      |> select([s, b, u, a, c, v], %{
        bin: b.min,
        resolution: ^resolution,
        swaps: fragment("COALESCE(?, 0)", over(count(s.idx), :bins)),
        affiliate_fee: fragment("COALESCE(?, 0)", over(sum(s.affiliate_fee_in_usd), :bins)),
        liquidity_fee_paid_to_tc:
          fragment("COALESCE(?, 0)", over(sum(s.liquidity_fee_in_usd), :bins)),
        liquidity_fee_paid_to_tc_share_over_total:
          fragment(
            "COALESCE(?, 0)",
            over(sum(s.liquidity_fee_in_usd), :bins) / v.volume
          ),
        volume: fragment("COALESCE(?, 0)", over(sum(s.volume_usd), :bins)),
        volume_share_over_total:
          fragment(
            "COALESCE(?, 0)",
            over(sum(s.volume_usd), :bins) / v.volume
          ),
        unique_swap_users: fragment("COALESCE(?, 0)", u.unique_swap_users),
        swap_volume_by_asset: fragment("COALESCE(?, '[]')", a.data),
        swap_volume_by_chain: fragment("COALESCE(?, '[]')", c.data)
      })
      |> windows([s, b],
        bins: [
          partition_by: b.min,
          order_by: s.timestamp,
          frame: fragment("RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING")
        ]
      )
      |> subquery()
      |> where([s], s.bin >= ^from and s.bin <= ^to)
      |> select([s], %{
        bin: s.bin,
        resolution: s.resolution,
        swaps: %{
          value: s.swaps,
          moving_avg: fragment("COALESCE(?, 0)", over(avg(s.swaps), :ma))
        },
        affiliate_fee: %{
          value: s.affiliate_fee,
          moving_avg: fragment("COALESCE(?, 0)", over(avg(s.affiliate_fee), :ma))
        },
        liquidity_fee_paid_to_tc: %{
          value: s.liquidity_fee_paid_to_tc,
          moving_avg: fragment("COALESCE(?, 0)", over(avg(s.liquidity_fee_paid_to_tc), :ma))
        },
        liquidity_fee_paid_to_tc_share_over_total: s.liquidity_fee_paid_to_tc_share_over_total,
        volume: %{
          value: s.volume,
          moving_avg: fragment("COALESCE(?, 0)", over(avg(s.volume), :ma))
        },
        volume_share_over_total: s.volume_share_over_total,
        unique_swap_users: s.unique_swap_users,
        swap_volume_by_asset: s.swap_volume_by_asset,
        swap_volume_by_chain: s.swap_volume_by_chain
      })
      |> windows([s],
        ma: [
          partition_by: s.bin,
          order_by: s.bin,
          frame: fragment("ROWS BETWEEN ? PRECEDING AND CURRENT ROW", ^period)
        ]
      )
    end
  end

  # Builds a CTE query to calculate unique swap users per bin.

  # It:
  #   - Starts with the base query for the specified affiliate.
  #   - Joins the "bins" table.
  #   - Groups the data by the bin minimum value.
  #   - Selects the bin and counts distinct swap users.
  defp unique_users_cte(from, to, affiliate) do
    base_query(from, to, affiliate)
    |> subquery()
    |> join(:inner, [s], b in "bins", on: s.timestamp >= b.min and s.timestamp < b.max)
    |> group_by([s, b], b.min)
    |> select([s, b], %{
      bin: b.min,
      unique_swap_users: count(fragment("DISTINCT ?", s.from))
    })
  end

  # Builds a CTE query to aggregate swap volume by asset per bin.

  # It:
  #   - Uses the base query for the specified affiliate.
  #   - Joins the "bins" table with a right join.
  #   - Selects each bin and computes the aggregated volume for each asset.
  #   - Applies window functions to compute weighted sums.
  #   - Groups and aggregates the results into JSONB format.
  defp volume_by_asset_cte(from, to, affiliate) do
    base_query(from, to, affiliate)
    |> subquery()
    |> join(:right, [s], b in "bins", on: s.timestamp >= b.min and s.timestamp < b.max)
    |> select([s, b], %{
      bin: b.min,
      data: %{
        asset: s.pool,
        weight:
          over(
            sum(fragment("CASE WHEN pool = ? THEN ? ELSE 0 END", s.pool, s.volume_usd)),
            :bins
          ) /
            over(sum(s.volume_usd), :bins),
        value:
          over(
            sum(fragment("CASE WHEN pool = ? THEN ? ELSE 0 END", s.pool, s.volume_usd)),
            :bins
          )
      }
    })
    |> windows([s, b],
      bins: [
        partition_by: b.min,
        order_by: s.timestamp,
        frame: fragment("RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING")
      ]
    )
    |> subquery()
    |> group_by([s], [s.bin, s.data])
    |> select([s], %{
      bin: s.bin,
      data: fragment("array_agg(?)", s.data)
    })
  end

  # Builds a CTE query to aggregate swap volume by chain per bin.

  # It:
  #   - Uses the base query for the specified affiliate.
  #   - Joins the "bins" table with a right join.
  #   - Selects each bin and computes the aggregated volume for each chain.
  #   - Applies window functions to compute weighted sums.
  #   - Groups and aggregates the results into JSONB format.
  defp volume_by_chain_cte(from, to, affiliate) do
    base_query(from, to, affiliate)
    |> subquery()
    |> join(:right, [s], b in "bins", on: s.timestamp >= b.min and s.timestamp < b.max)
    |> select([s, b], %{
      bin: b.min,
      data: %{
        chain: s.chain,
        weight:
          over(
            sum(fragment("CASE WHEN chain = ? THEN ? ELSE 0 END", s.chain, s.volume_usd)),
            :bins
          ) /
            over(sum(s.volume_usd), :bins),
        value:
          over(
            sum(fragment("CASE WHEN chain = ? THEN ? ELSE 0 END", s.chain, s.volume_usd)),
            :bins
          )
      }
    })
    |> windows([s, b],
      bins: [
        partition_by: b.min,
        order_by: s.timestamp,
        frame: fragment("RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING")
      ]
    )
    |> subquery()
    |> group_by([s], [s.bin, s.data])
    |> select([s], %{
      bin: s.bin,
      data: fragment("array_agg(?)", s.data)
    })
  end

  # Builds a CTE query to compute the total swap volume per bin.

  # It:
  #   - Filters swaps by timestamp.
  #   - Uses a right join with the "bins" table.
  #   - Sums the volume per bin.
  #   - Applies a window function to aggregate the sum.
  defp total_volume_cte(from, to) do
    Swap
    |> where([s], s.timestamp >= ^from and s.timestamp <= ^to)
    |> Swaps.sort(:desc)
    |> subquery()
    |> join(:right, [s], b in "bins", on: s.timestamp >= b.min and s.timestamp < b.max)
    |> select([s, b], %{
      bin: b.min,
      volume: fragment("COALESCE(?, 0)", over(sum(s.volume_usd), :bins))
    })
    |> windows([s, b],
      bins: [
        partition_by: b.min,
        order_by: s.timestamp,
        frame: fragment("RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING")
      ]
    )
  end
end
