defmodule Rujira.Analytics.SwapQueries do
  @moduledoc """
  Provides queries for aggregating swap data into time bins with various computed metrics.

  This module constructs several Common Table Expressions (CTEs) to derive:
    - The number of unique swap users per time bin.
    - The breakdown of swap volume by asset, including computed weighted volume.
    - The breakdown of swap volume by chain, including computed weighted volume.
    - The total swap volume per time bin.

  The main `snapshots/4` function builds on these CTEs to aggregate data for each bin,
  calculating sums, ratios, and moving averages to facilitate time-series analysis.
  """

  import Ecto.Query
  alias Rujira.Analytics.Common
  alias Thorchain.Swaps.Swap
  alias Rujira.Resolution

  # Returns a base query filtering swaps by a given time range and affiliate.
  #
  # Filters applied:
  #   - The swap's timestamp is between `from` and `to`.
  #   - The swap has a non-nil affiliate that exactly matches the given `affiliate`.
  defp base_query(from, to, affiliate) do
    Swap
    |> where(
      [s],
      s.timestamp >= ^from and s.timestamp <= ^to and
        not is_nil(s.affiliate) and s.affiliate == ^affiliate
    )
  end

  @doc """
  Aggregates swap data and computes various metrics for snapshots.

  The function performs the following steps:
    - Adjusts the starting timestamp using `Resolution.shift_from_back/3`.
    - Uses a base query (with a fixed affiliate "rj") to select swaps within the adjusted range.
    - Joins the swaps with pre-defined time bins and attaches several CTEs:
        • Unique swap users per bin.
        • Volume breakdown by asset.
        • Volume breakdown by chain.
        • Total volume per bin.
    - Aggregates various metrics (such as swap counts, fees, and volumes) per bin.
    - Applies window functions to compute moving averages over the specified period.

  The final result returns one row per bin containing aggregated data along with moving averages.
  """
  def snapshots(from, to, resolution, period) do
    with shifted_from <- Common.shift_from_back(from, period, resolution) do
      base_query(shifted_from, to, "rj")
      |> subquery()
      |> join(:right, [s], b in "bins", on: s.timestamp >= b.min and s.timestamp < b.max)
      |> Common.with_range(shifted_from, Resolution.truncate(to, resolution), resolution)
      |> volume_by_asset_cte(shifted_from, to, "rj")
      |> volume_by_chain_cte(shifted_from, to, "rj")
      |> unique_users_cte(shifted_from, to, "rj")
      |> total_volume_cte(shifted_from, to)
      |> join(:left, [s, b], a in "volume_by_asset", on: a.bin == b.min)
      |> join(:left, [s, b, a], c in "volume_by_chain", on: c.bin == b.min)
      |> join(:left, [s, b, a, c], u in "unique_users", on: u.bin == b.min)
      |> join(:left, [s, b, a, c, u], v in "total_volume", on: v.bin == b.min)
      |> select([s, b, a, c, u, v], %{
        bin: b.min,
        resolution: ^resolution,
        swaps: fragment("COALESCE(?, 0)", over(count(s.idx), :bins)),
        affiliate_fee:
          fragment("COALESCE(CAST(? AS bigint), 0)", over(sum(s.affiliate_fee_in_usd), :bins)),
        liquidity_fee_paid_to_tc:
          fragment("COALESCE(CAST(? AS bigint), 0)", over(sum(s.liquidity_fee_in_usd), :bins)),
        liquidity_fee_paid_to_tc_share_over_total:
          fragment("COALESCE(?, 0)", over(sum(s.liquidity_fee_in_usd), :bins) / v.volume),
        volume: fragment("COALESCE(CAST(? AS bigint), 0)", over(sum(s.volume_usd), :bins)),
        volume_share_over_total:
          fragment("COALESCE(?, 0)", over(sum(s.volume_usd), :bins) / v.volume),
        swap_volume_by_asset: fragment("COALESCE(?, '[]')", a.data),
        swap_volume_by_chain: fragment("COALESCE(?, '[]')", c.data),
        unique_swap_users: fragment("COALESCE(?, 0)", u.unique_swap_users)
      })
      |> windows([s, b],
        bins: [
          partition_by: b.min,
          order_by: s.timestamp,
          frame: fragment("RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING")
        ]
      )
      |> subquery()
      |> group_by([:bin, :swap_volume_by_asset, :swap_volume_by_chain])
      |> select([q], %{
        bin: q.bin,
        resolution: ^resolution,
        swaps: max(q.swaps),
        affiliate_fee: max(q.affiliate_fee),
        liquidity_fee_paid_to_tc: max(q.liquidity_fee_paid_to_tc),
        liquidity_fee_paid_to_tc_share_over_total:
          max(q.liquidity_fee_paid_to_tc_share_over_total),
        volume: max(q.volume),
        volume_share_over_total: max(q.volume_share_over_total),
        swap_volume_by_asset: q.swap_volume_by_asset,
        swap_volume_by_chain: q.swap_volume_by_chain,
        unique_swap_users: max(q.unique_swap_users)
      })
      |> subquery()
      |> select([s], %{
        bin: s.bin,
        resolution: s.resolution,
        swaps_value: s.swaps,
        swaps_moving_avg: fragment("COALESCE(CAST(? AS bigint), 0)", over(avg(s.swaps), :ma)),
        affiliate_fee_value: s.affiliate_fee,
        affiliate_fee_moving_avg:
          fragment("COALESCE(CAST(? AS bigint), 0)", over(avg(s.affiliate_fee), :ma)),
        liquidity_fee_paid_to_tc_value: s.liquidity_fee_paid_to_tc,
        liquidity_fee_paid_to_tc_moving_avg:
          fragment("COALESCE(CAST(? AS bigint), 0)", over(avg(s.liquidity_fee_paid_to_tc), :ma)),
        liquidity_fee_paid_to_tc_share_over_total: s.liquidity_fee_paid_to_tc_share_over_total,
        volume_value: s.volume,
        volume_moving_avg:
          fragment("COALESCE(CAST(? AS bigint), 0)", over(avg(coalesce(s.volume, 0)), :ma)),
        volume_share_over_total: s.volume_share_over_total,
        unique_swap_users: s.unique_swap_users,
        swap_volume_by_asset: s.swap_volume_by_asset,
        swap_volume_by_chain: s.swap_volume_by_chain
      })
      |> windows([s],
        ma: [
          order_by: s.bin,
          frame: fragment("ROWS BETWEEN ? PRECEDING AND CURRENT ROW", ^period)
        ]
      )
      |> subquery()
      |> where([s], s.bin >= ^from and s.bin <= ^to)
      |> select([s], %{
        bin: s.bin,
        resolution: s.resolution,
        swaps: %{
          value: s.swaps_value,
          moving_avg: s.swaps_moving_avg
        },
        affiliate_fee: %{
          value: s.affiliate_fee_value,
          moving_avg: s.affiliate_fee_moving_avg
        },
        liquidity_fee_paid_to_tc: %{
          value: s.liquidity_fee_paid_to_tc_value,
          moving_avg: s.liquidity_fee_paid_to_tc_moving_avg
        },
        liquidity_fee_paid_to_tc_share_over_total: s.liquidity_fee_paid_to_tc_share_over_total,
        volume: %{
          value: s.volume_value,
          moving_avg: s.volume_moving_avg
        },
        volume_share_over_total: s.volume_share_over_total,
        unique_swap_users: s.unique_swap_users,
        swap_volume_by_asset: s.swap_volume_by_asset,
        swap_volume_by_chain: s.swap_volume_by_chain
      })
      |> order_by(asc: :bin)
    end
  end

  # Constructs a CTE that calculates the number of unique swap users per time bin.
  #
  # Steps:
  #   - Uses the base query filtered by time range and affiliate.
  #   - Joins with the "bins" table to assign swaps to their respective bins.
  #   - Groups the data by the minimum timestamp of each bin.
  #   - Selects each bin along with the count of distinct swap initiators (using `s.from`).
  defp unique_users_cte(q, from, to, affiliate) do
    query =
      base_query(from, to, affiliate)
      |> subquery()
      |> join(:right, [s], b in "bins", on: s.timestamp >= b.min and s.timestamp < b.max)
      |> group_by([s, b], b.min)
      |> select([s, b], %{
        bin: b.min,
        unique_swap_users: count(fragment("DISTINCT ?", s.from))
      })

    with_cte(q, "unique_users", as: ^query)
  end

  # Constructs a CTE that aggregates swap volume by asset for each time bin.
  #
  # Process:
  #   - Starts with the base query filtered by time and affiliate.
  #   - Joins with the "bins" table using a right join to include all bins.
  #   - Groups results by bin and asset (identified by `s.pool`), summing volume in USD.
  #   - Computes the total volume per bin and then, for each asset,
  #     calculates a weighted volume (as a ratio scaled to a large constant) and rounds it.
  #   - Aggregates the per-asset data into a JSONB array for each bin.
  defp volume_by_asset_cte(q, from, to, affiliate) do
    asset_volume_query =
      base_query(from, to, affiliate)
      |> subquery()
      |> join(:right, [s], b in "bins", on: s.timestamp >= b.min and s.timestamp < b.max)
      |> group_by([s, b], [b.min, s.pool])
      |> select([s, b], %{
        bin: b.min,
        asset: s.pool,
        volume: sum(s.volume_usd)
      })

    # Compute the total volume for each bin.
    total_volume_query =
      asset_volume_query
      |> subquery()
      |> group_by([av], av.bin)
      |> select([av], %{
        bin: av.bin,
        total_volume: sum(av.volume)
      })

    final_query =
      asset_volume_query
      |> subquery()
      |> join(:right, [av], tv in subquery(total_volume_query), on: av.bin == tv.bin)
      |> group_by([av, tv], av.bin)
      |> select([av, tv], %{
        bin: av.bin,
        data:
          fragment(
            "COALESCE(jsonb_agg(DISTINCT jsonb_build_object('asset', ?, 'weight', round(?::numeric), 'volume', ?)) FILTER (WHERE ? IS NOT NULL), '[]'::jsonb)",
            av.asset,
            av.volume / tv.total_volume * 1_000_000_000_000,
            av.volume,
            av.asset
          )
      })

    with_cte(q, "volume_by_asset", as: ^final_query)
  end

  # Constructs a CTE that aggregates swap volume by chain for each time bin.
  #
  # Process:
  #   - Starts with the base query filtered by time and affiliate.
  #   - Uses a right join with the "bins" table to cover all bins.
  #   - Groups results by bin and chain, summing the USD volume.
  #   - Computes the total volume per bin and then, for each chain,
  #     calculates a weighted volume (as a ratio scaled to a large constant) and rounds it.
  #   - Aggregates the per-chain data into a JSONB array for each bin.
  defp volume_by_chain_cte(q, from, to, affiliate) do
    chain_volume_query =
      base_query(from, to, affiliate)
      |> subquery()
      |> join(:right, [s], b in "bins", on: s.timestamp >= b.min and s.timestamp < b.max)
      |> group_by([s, b], [b.min, s.chain])
      |> select([s, b], %{
        bin: b.min,
        chain: s.chain,
        volume: sum(s.volume_usd)
      })

    total_volume_query =
      chain_volume_query
      |> subquery()
      |> group_by([av], av.bin)
      |> select([av], %{
        bin: av.bin,
        total_volume: sum(av.volume)
      })

    final_query =
      chain_volume_query
      |> subquery()
      |> join(:right, [av], tv in subquery(total_volume_query), on: av.bin == tv.bin)
      |> group_by([av, tv], av.bin)
      |> select([av, tv], %{
        bin: av.bin,
        data:
          fragment(
            "COALESCE(jsonb_agg(DISTINCT jsonb_build_object('chain', ?, 'weight', round(?::numeric), 'volume', ?)) FILTER (WHERE ? IS NOT NULL), '[]'::jsonb)",
            av.chain,
            av.volume / tv.total_volume * 1_000_000_000_000,
            av.volume,
            av.chain
          )
      })

    with_cte(q, "volume_by_chain", as: ^final_query)
  end

  # Constructs a CTE that computes the total swap volume per time bin.
  #
  # Process:
  #   - Filters swaps based on the provided time range.
  #   - Uses a right join with the "bins" table to ensure all bins are represented.
  #   - Groups data by bin and sums the USD volume for all swaps in that bin.
  defp total_volume_cte(q, from, to) do
    query =
      Swap
      |> where([s], s.timestamp >= ^from and s.timestamp <= ^to)
      |> join(:right, [s], b in "bins", on: s.timestamp >= b.min and s.timestamp < b.max)
      |> group_by([s, b], b.min)
      |> select([s, b], %{
        bin: b.min,
        volume: fragment("COALESCE(?, 0)", sum(s.volume_usd))
      })

    with_cte(q, "total_volume", as: ^query)
  end
end
