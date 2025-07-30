defmodule Rujira.Analytics.Swap do
  @moduledoc """
  Handles queries for base layer swap analytics.
  """
  alias Rujira.Analytics.Common
  alias Rujira.Analytics.Swap.AddressBin
  alias Rujira.Analytics.Swap.AffiliateBin
  alias Rujira.Analytics.Swap.AssetBin
  alias Rujira.Analytics.Swap.ChainBin
  alias Rujira.Repo

  import Ecto.Query

  def insert_affiliate(entries, time),
    do: do_insert_bin(entries, time, AffiliateBin)

  def insert_address(entries, time),
    do: do_insert_bin(entries, time, AddressBin)

  def insert_chain(entries, time),
    do: do_insert_bin(entries, time, ChainBin)

  def insert_asset(entries, time),
    do: do_insert_bin(entries, time, AssetBin)

  defp do_insert_bin(entries, time, bin_module) do
    entries_with_bins = expand_with_bins(entries, time)

    Task.async_stream([bin_module], & &1.update(entries_with_bins))
    |> Enum.map(fn {:ok, _} -> :ok end)
  end

  def update_affiliate(entries, time) do
    entries_with_bins = expand_with_bins(entries, time)

    AffiliateBin
    |> Repo.insert_all(
      entries_with_bins,
      on_conflict:
        from(c in AffiliateBin,
          update: [
            set: [
              count: c.count,
              revenue: fragment("EXCLUDED.revenue + ?", c.revenue),
              liquidity_fee: c.liquidity_fee,
              volume: c.volume
            ]
          ]
        ),
      conflict_target: [:resolution, :bin, :affiliate],
      returning: true
    )
  end

  defp expand_with_bins(entries, time) do
    bins = Common.active(time)

    entries
    |> Enum.flat_map(fn entry ->
      Enum.map(bins, fn {r, b} -> to_bin(entry, {r, b}) end)
    end)
  end

  defp to_bin(entry, {r, b}) do
    now = DateTime.utc_now()

    entry
    |> Map.merge(%{resolution: r, bin: b, inserted_at: now, updated_at: now})
  end

  def bins(from, to, resolution, period) do
    with shifted_from <- Common.shift_from_back(from, period, resolution) do
      AffiliateBin
      |> where(
        [a],
        a.resolution == ^resolution and a.bin >= ^shifted_from and a.bin < ^to and
          a.affiliate == "rj"
      )
      |> subquery()
      |> Common.with_range(shifted_from, to, resolution)
      |> totals_cte(shifted_from, to, resolution)
      |> unique_users_cte(shifted_from, to, resolution)
      |> join(:right, [a], b in "bins", on: a.bin == b.min)
      |> join(:left, [a, b], t in "totals", on: t.bin == b.min)
      |> join(:left, [a, b, t], u in "unique_users", on: u.bin == b.min)
      |> select([a, b, t, u], %{
        resolution: ^resolution,
        bin: b.min,
        affiliate: "rj",
        total_swaps: fragment("CAST(COALESCE(ROUND(?), 0) AS BIGINT)", a.count),
        revenue: fragment("CAST(COALESCE(?, 0) AS BIGINT)", a.revenue),
        liquidity_fee_paid_to_tc: fragment("CAST(COALESCE(?, 0) AS BIGINT)", a.liquidity_fee),
        liquidity_fee_paid_to_tc_share_over_total:
          fragment("COALESCE(?, 0)", a.liquidity_fee / t.liquidity_fee),
        volume: fragment("CAST(COALESCE(?, 0) AS BIGINT)", a.volume),
        volume_share_over_total: fragment("COALESCE(?, 0)", a.volume / t.volume),
        unique_swap_users: fragment("CAST(COALESCE(?, 0) AS BIGINT)", u.unique_swap_users)
      })
      |> subquery()
      |> select([s], %{
        bin: s.bin,
        resolution: s.resolution,
        total_swaps_value: s.total_swaps,
        total_swaps_moving_avg:
          fragment("COALESCE(CAST(? AS bigint), 0)", over(avg(s.total_swaps), :ma)),
        revenue_value: s.revenue,
        revenue_moving_avg: fragment("COALESCE(CAST(? AS bigint), 0)", over(avg(s.revenue), :ma)),
        liquidity_fee_paid_to_tc_value: s.liquidity_fee_paid_to_tc,
        liquidity_fee_paid_to_tc_moving_avg:
          fragment("COALESCE(CAST(? AS bigint), 0)", over(avg(s.liquidity_fee_paid_to_tc), :ma)),
        liquidity_fee_paid_to_tc_share_over_total: s.liquidity_fee_paid_to_tc_share_over_total,
        volume_value: s.volume,
        volume_moving_avg:
          fragment("COALESCE(CAST(? AS bigint), 0)", over(avg(coalesce(s.volume, 0)), :ma)),
        volume_share_over_total: s.volume_share_over_total,
        unique_swap_users: s.unique_swap_users,
        unique_swap_users_moving_avg:
          fragment(
            "COALESCE(CAST(? AS bigint), 0)",
            over(avg(coalesce(s.unique_swap_users, 0)), :ma)
          )
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
          value: s.total_swaps_value,
          moving_avg: s.total_swaps_moving_avg
        },
        revenue: %{
          value: s.revenue_value,
          moving_avg: s.revenue_moving_avg
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
        unique_swap_users: %{
          value: s.unique_swap_users,
          moving_avg: s.unique_swap_users_moving_avg
        }
      })
      |> order_by(asc: :bin)
    end
  end

  defp totals_cte(q, shifted_from, to, resolution) do
    query =
      AffiliateBin
      |> where(
        [a],
        a.resolution == ^resolution and a.bin >= ^shifted_from and a.bin < ^to
      )
      |> subquery()
      |> join(:right, [a], b in "bins", on: a.bin == b.min)
      |> select([a, b], %{
        bin: b.min,
        liquidity_fee: fragment("COALESCE(SUM(?), 0)", a.liquidity_fee),
        volume: fragment("COALESCE(SUM(?), 0)", a.volume)
      })
      |> group_by([a, b], b.min)

    with_cte(q, "totals", as: ^query)
  end

  defp unique_users_cte(q, shifted_from, to, resolution) do
    query =
      AddressBin
      |> where(
        [a],
        a.resolution == ^resolution and a.bin >= ^shifted_from and a.bin < ^to and
          a.affiliate == "rj"
      )
      |> subquery()
      |> join(:right, [a], b in "bins", on: a.bin == b.min)
      |> select([a, b], %{
        bin: b.min,
        unique_swap_users: fragment("COALESCE(ROUND(SUM(?)), 0)", a.address_weight)
      })
      |> group_by([a, b], b.min)

    with_cte(q, "unique_users", as: ^query)
  end

  def volume_by_asset(from, to) do
    {:ok,
     AssetBin
     |> where(
       [a],
       a.bin >= ^from and a.bin < ^to and a.resolution == "1D" and a.affiliate == "rj"
     )
     |> select([a], %{
       asset: a.asset,
       volume: fragment("CAST(COALESCE(SUM(?), 0) AS BIGINT)", a.volume)
     })
     |> group_by([a], a.asset)
     |> Repo.all()
     |> add_weight()}
  end

  def volume_by_chain(from, to) do
    {:ok,
     ChainBin
     |> where(
       [c],
       c.bin >= ^from and c.bin < ^to and c.resolution == "1D" and c.affiliate == "rj"
     )
     |> select([c], %{
       source_chain: c.source_chain,
       volume: fragment("CAST(COALESCE(SUM(?), 0) AS BIGINT)", c.volume)
     })
     |> group_by([c], c.source_chain)
     |> Repo.all()
     |> add_weight()}
  end

  def add_weight(items) when is_list(items) do
    total = Enum.reduce(items, Decimal.new(0), fn %{volume: v}, acc -> Decimal.add(acc, v) end)

    Enum.map(items, fn %{volume: volume} = item ->
      weight =
        case Decimal.compare(total, 0) do
          :gt -> Decimal.div(volume, total)
          _ -> Decimal.new(0)
        end

      Map.put(item, :weight, weight)
    end)
  end
end
