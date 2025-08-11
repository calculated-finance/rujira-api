defmodule Rujira.Analytics.Staking do
  @moduledoc """
  Handles queries for staking analytics.
  """
  alias Rujira.Analytics.Common
  alias Rujira.Analytics.Staking.RevenueBin
  alias Rujira.Repo
  alias Rujira.Staking

  import Ecto.Query
  require Logger

  use Supervisor

  def start_link(_) do
    children =
      Common.resolutions()
      |> Enum.map(&Supervisor.child_spec({RevenueBin, &1}, id: &1))
      |> Enum.concat(staking_children())

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp staking_children do
    with {:ok, pools} <- Staking.list_pools() do
      Enum.map(pools, &Supervisor.child_spec({__MODULE__.Indexer, &1}, id: &1.address))
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def insert_bins(time, resolution) do
    now = DateTime.utc_now()

    new =
      from(c in RevenueBin,
        where: c.resolution == ^resolution,
        distinct: c.contract,
        order_by: [desc: c.bin]
      )
      |> Repo.all()
      |> Enum.map(&RevenueBin.default(&1, time, now))

    Repo.insert_all(RevenueBin, new,
      # Conflict will be hit if race condition has triggered insert before this is reached
      on_conflict: :nothing,
      returning: true
    )
    |> broadcast_bins()
  end

  def update_bins(pool) do
    entries =
      Common.active(pool.timestamp)
      |> Enum.map(&to_bin(pool, &1))

    RevenueBin
    |> Repo.insert_all(
      entries,
      on_conflict: RevenueBin.handle_conflict(),
      conflict_target: [:resolution, :bin, :contract],
      returning: true
    )
    |> broadcast_bins()
  end

  defp to_bin(pool, {resolution, bin}) do
    now = DateTime.utc_now()

    pool
    |> Map.merge(%{
      id: RevenueBin.id(pool.contract, resolution, bin),
      resolution: resolution,
      bin: bin,
      inserted_at: now,
      updated_at: now
    })
    |> Map.drop([:timestamp])
  end

  defp broadcast_bins({_count, bins}) do
    for bin <- bins do
      Logger.debug("#{__MODULE__} broadcast bin #{bin.id}")

      Rujira.Events.publish_edge(
        :analytics_staking_bin,
        "#{bin.contract}/#{bin.resolution}",
        bin.id
      )
    end
  end

  def summary(contract) do
    from = Common.shift_from_back(DateTime.utc_now(), 7, "1D")
    to = DateTime.utc_now()

    RevenueBin
    |> where(
      [r],
      r.contract == ^contract and r.resolution == "1D" and r.bin >= ^from and r.bin < ^to
    )
    |> group_by([r], r.contract)
    |> select([r], %{
      apr: coalesce(avg(r.account_apr), 0),
      apy: coalesce(avg(r.liquid_apy), 0),
      revenue: coalesce(sum(r.account_revenue), 0) |> type(:integer)
    })
    |> Repo.one()
    |> case do
      nil -> {:ok, nil}
      summary -> {:ok, summary}
    end
  end

  def bins(from, to, resolution, period, contract) do
    shifted_from = Common.shift_from_back(from, period, resolution)

    # First subquery: get base data with proper field mapping
    base_query =
      RevenueBin
      |> where(
        [r],
        r.resolution == ^resolution and
          r.contract == ^contract and
          r.bin >= ^shifted_from and
          r.bin < ^to
      )
      |> select([r], %{
        bin: r.bin,
        resolution: ^resolution,

        # lp weight -> if single side == 1 otherwise proportion of base denom / lp
        lp_weight: coalesce(r.lp_weight, 0),

        # Revenue fields - map to GraphQL field names
        total_revenue: coalesce(r.total_revenue, 0),
        account_revenue: coalesce(r.account_revenue, 0),
        liquid_revenue: coalesce(r.liquid_revenue, 0),

        # Balance fields - map to GraphQL field names
        total_balance_staked: coalesce(r.total_balance, 0),
        account_balance_staked: coalesce(r.account_balance, 0),
        liquid_balance_staked: coalesce(r.liquid_balance, 0),

        # Value fields - map to GraphQL field names
        total_value_staked: coalesce(r.total_value, 0),
        account_value_staked: coalesce(r.account_value, 0),
        liquid_value_staked: coalesce(r.liquid_value, 0),

        # APR/APY fields - map to GraphQL field names
        account_apr: coalesce(r.account_apr, 0),
        liquid_apy: coalesce(r.liquid_apy, 0),
        account_revenue_per_share: coalesce(r.account_revenue_per_share, 0),

        # Inflow/Outflow fields - add missing fields
        inflow_account_staked: coalesce(r.account_inflows, 0),
        inflow_liquid_staked: coalesce(r.liquid_inflows, 0),
        outflow_account_staked: coalesce(r.account_outflows, 0),
        outflow_liquid_staked: coalesce(r.liquid_outflows, 0)
      })

    # Second query: add moving averages and format output
    base_query
    |> subquery()
    |> windows([s],
      ma: [
        order_by: s.bin,
        frame: fragment("ROWS BETWEEN ? PRECEDING AND CURRENT ROW", ^period)
      ]
    )
    |> where([s], s.bin >= ^from and s.bin <= ^to)
    |> select([s], %{
      bin: s.bin,
      resolution: s.resolution,
      lp_weight: s.lp_weight,

      # Revenue with moving averages
      total_revenue: %{
        value: s.total_revenue,
        moving_avg: avg(s.total_revenue) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      account_revenue: %{
        value: s.account_revenue,
        moving_avg: avg(s.account_revenue) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      liquid_revenue: %{
        value: s.liquid_revenue,
        moving_avg: avg(s.liquid_revenue) |> over(:ma) |> coalesce(0) |> type(:integer)
      },

      # Balance with moving averages
      total_balance_staked: %{
        value: s.total_balance_staked,
        moving_avg: avg(s.total_balance_staked) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      account_balance_staked: %{
        value: s.account_balance_staked,
        moving_avg: avg(s.account_balance_staked) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      liquid_balance_staked: %{
        value: s.liquid_balance_staked,
        moving_avg: avg(s.liquid_balance_staked) |> over(:ma) |> coalesce(0) |> type(:integer)
      },

      # Value with moving averages
      total_value_staked: %{
        value: s.total_value_staked,
        moving_avg: avg(s.total_value_staked) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      account_value_staked: %{
        value: s.account_value_staked,
        moving_avg: avg(s.account_value_staked) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      liquid_value_staked: %{
        value: s.liquid_value_staked,
        moving_avg: avg(s.liquid_value_staked) |> over(:ma) |> coalesce(0) |> type(:integer)
      },

      # APR/APY with moving averages
      account_apr: %{
        value: s.account_apr,
        moving_avg: avg(s.account_apr) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      liquid_apy: %{
        value: s.liquid_apy,
        moving_avg: avg(s.liquid_apy) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      account_revenue_per_share: %{
        value: s.account_revenue_per_share,
        moving_avg: avg(s.account_revenue_per_share) |> over(:ma) |> coalesce(0) |> type(:integer)
      },

      # Inflow fields with moving averages
      inflow_account_staked: %{
        value: s.inflow_account_staked,
        moving_avg: avg(s.inflow_account_staked) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      inflow_liquid_staked: %{
        value: s.inflow_liquid_staked,
        moving_avg: avg(s.inflow_liquid_staked) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      inflow_total_staked: %{
        value: s.inflow_account_staked + s.inflow_liquid_staked,
        moving_avg:
          avg(s.inflow_account_staked + s.inflow_liquid_staked)
          |> over(:ma)
          |> coalesce(0)
          |> type(:integer)
      },

      # Outflow fields with moving averages
      outflow_account_staked: %{
        value: s.outflow_account_staked,
        moving_avg: avg(s.outflow_account_staked) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      outflow_liquid_staked: %{
        value: s.outflow_liquid_staked,
        moving_avg: avg(s.outflow_liquid_staked) |> over(:ma) |> coalesce(0) |> type(:integer)
      },
      outflow_total_staked: %{
        value: s.outflow_account_staked + s.outflow_liquid_staked,
        moving_avg:
          avg(s.outflow_account_staked + s.outflow_liquid_staked)
          |> over(:ma)
          |> coalesce(0)
          |> type(:integer)
      }
    })
    |> order_by(asc: :bin)
  end
end
