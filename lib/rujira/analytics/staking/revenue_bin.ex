defmodule Rujira.Analytics.Staking.RevenueBin do
  @moduledoc """
  The RevenueBin schema aggregates staking revenue data.
  """

  use Ecto.Schema
  use GenServer

  alias Rujira.Analytics.Staking
  alias Rujira.Resolution

  import Ecto.Query

  require Logger

  # TODO autoliquid_bond richlist we can use the holders to retrive the data
  # TODO account_bond richlist we need to query the contract

  @type t :: %__MODULE__{
          resolution: String.t(),
          bin: DateTime.t(),
          contract: String.t(),
          total_revenue: non_neg_integer(),
          liquid_revenue: non_neg_integer(),
          account_revenue: non_neg_integer(),
          total_balance: non_neg_integer(),
          liquid_balance: non_neg_integer(),
          account_balance: non_neg_integer(),
          total_value: non_neg_integer(),
          liquid_value: non_neg_integer(),
          account_value: non_neg_integer(),
          account_apr: Decimal.t(),
          account_revenue_per_share: Decimal.t(),
          liquid_redemption_rate_start: Decimal.t(),
          liquid_redemption_rate_current: Decimal.t(),
          liquid_apy: Decimal.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key false
  schema "rujira_analytics_staking_revenue_bins" do
    field :id, :string

    field :resolution, :string, primary_key: true
    field :bin, :utc_datetime, primary_key: true
    field :contract, :string, primary_key: true

    # lp weight -> if single side == 1 otherwise proportion of base denom / lp
    field :lp_weight, :decimal

    # revenue is already in USD
    # revenue = total revenue generated from staking in a specific bin
    field :total_revenue, :integer
    field :liquid_revenue, :integer
    field :account_revenue, :integer

    # total_balance in denom = liquid_balance + account_balance
    field :total_balance, :integer
    field :liquid_balance, :integer
    field :account_balance, :integer

    # total_value = liquid_value + account_value
    field :total_value, :integer
    field :liquid_value, :integer
    field :account_value, :integer

    # APR calculated in the bin period
    # APR = (account_revenue / account_value) * bin period in years
    field :account_apr, :decimal
    # account_revenue_per_share = account_revenue / account_balance
    field :account_revenue_per_share, :decimal

    # liquid_bond data
    field :liquid_redemption_rate_start, :decimal
    field :liquid_redemption_rate_current, :decimal
    field :liquid_apy, :decimal

    # inflows/outflows
    field :account_inflows, :integer
    field :account_outflows, :integer
    field :liquid_inflows, :integer
    field :liquid_outflows, :integer

    timestamps(type: :utc_datetime_usec)
  end

  # default values for new bin
  def default(prev_bin, time, now) do
    %{
      # Identifiers
      id: id(prev_bin.contract, prev_bin.resolution, time),
      contract: prev_bin.contract,
      resolution: prev_bin.resolution,
      bin: time,

      # lp weight -> if single side == 1 otherwise proportion of base denom / lp
      lp_weight: prev_bin.lp_weight,

      # Revenue (reset to 0 for new bin)
      total_revenue: 0,
      account_revenue: 0,
      liquid_revenue: 0,

      # Balances (carry forward from previous bin)
      total_balance: prev_bin.total_balance,
      account_balance: prev_bin.account_balance,
      liquid_balance: prev_bin.liquid_balance,

      # Values (carry forward from previous bin)
      total_value: prev_bin.total_value,
      account_value: prev_bin.account_value,
      liquid_value: prev_bin.liquid_value,

      # Calculated metrics (reset to 0 for new bin)
      account_apr: 0,
      account_revenue_per_share: 0,
      liquid_apy: 0,

      # Redemption rates (carry forward current as start for new bin)
      liquid_redemption_rate_start: prev_bin.liquid_redemption_rate_current,
      liquid_redemption_rate_current: prev_bin.liquid_redemption_rate_current,

      # Flows (reset to 0 for new bin)
      account_inflows: 0,
      account_outflows: 0,
      liquid_inflows: 0,
      liquid_outflows: 0,

      # Timestamps
      inserted_at: now,
      updated_at: now
    }
  end

  # conflict handler for update
  def handle_conflict do
    from(b in __MODULE__,
      update: [
        set: [
          # lp weight -> if single side == 1 otherwise proportion of base denom / lp
          lp_weight: fragment("EXCLUDED.lp_weight"),

          # Revenue accumulations
          total_revenue: fragment("EXCLUDED.total_revenue + ?", b.total_revenue),
          account_revenue: fragment("EXCLUDED.account_revenue + ?", b.account_revenue),
          liquid_revenue: fragment("EXCLUDED.liquid_revenue + ?", b.liquid_revenue),

          # Balance and value replacements
          total_balance: fragment("EXCLUDED.total_balance"),
          account_balance: fragment("EXCLUDED.account_balance"),
          liquid_balance: fragment("EXCLUDED.liquid_balance"),
          total_value: fragment("EXCLUDED.total_value"),
          account_value: fragment("EXCLUDED.account_value"),
          liquid_value: fragment("EXCLUDED.liquid_value"),

          # Calculated metrics
          account_apr:
            fragment(
              """
              CASE
                WHEN EXCLUDED.account_value = 0 THEN 68
                ELSE ((? + EXCLUDED.account_revenue)::DECIMAL / EXCLUDED.account_value) *
                     CASE EXCLUDED.resolution
                       WHEN '1D' THEN 365
                       WHEN '1M' THEN 12
                       WHEN '12M' THEN 1
                       ELSE 0
                     END
              END
              """,
              b.account_revenue
            ),
          account_revenue_per_share:
            fragment(
              """
              CASE
                WHEN EXCLUDED.account_balance = 0 THEN 0
                ELSE (EXCLUDED.account_revenue + ?)::DECIMAL / EXCLUDED.account_balance * EXCLUDED.lp_weight
              END
              """,
              b.account_revenue
            ),
          liquid_redemption_rate_start:
            fragment(
              "COALESCE(?, EXCLUDED.liquid_redemption_rate_start)",
              b.liquid_redemption_rate_start
            ),
          liquid_redemption_rate_current: fragment("EXCLUDED.liquid_redemption_rate_current"),
          liquid_apy:
            fragment(
              """
              CASE
                WHEN EXCLUDED.liquid_value = 0 THEN 69
                ELSE POWER(EXCLUDED.liquid_redemption_rate_current::DECIMAL / ?,
                     1.0 / CASE EXCLUDED.resolution
                       WHEN '1D' THEN 365
                       WHEN '1M' THEN 12
                       WHEN '12M' THEN 1
                       ELSE 0
                     END) - 1
              END
              """,
              b.liquid_redemption_rate_start
            ),

          # Flow accumulations
          account_inflows: fragment("EXCLUDED.account_inflows + ?", b.account_inflows),
          account_outflows: fragment("EXCLUDED.account_outflows + ?", b.account_outflows),
          liquid_inflows: fragment("EXCLUDED.liquid_inflows + ?", b.liquid_inflows),
          liquid_outflows: fragment("EXCLUDED.liquid_outflows + ?", b.liquid_outflows)
        ]
      ]
    )
  end

  # ------------------- GenServer for empty RevenueBin creation ------------------- #

  def start_link(resolution) do
    GenServer.start_link(__MODULE__, resolution)
  end

  @impl true
  def init(resolution) do
    next =
      DateTime.utc_now()
      |> Resolution.truncate(resolution)
      |> Resolution.add(resolution)

    send(self(), next)
    {:ok, resolution}
  end

  @impl true
  def handle_info(time, resolution) do
    now = DateTime.utc_now()

    case DateTime.compare(time, now) do
      :gt ->
        now = DateTime.utc_now()
        delay = max(0, DateTime.diff(time, now, :millisecond))
        Process.send_after(self(), time, delay)
        {:noreply, resolution}

      _ ->
        Logger.debug("#{__MODULE__} #{resolution} #{time}")
        Staking.insert_bins(time, resolution)

        time = Resolution.add(time, resolution)
        delay = max(0, DateTime.diff(time, now, :millisecond))
        Process.send_after(self(), time, delay)
        {:noreply, resolution}
    end
  end

  def id(contract, resolution, bin), do: "#{contract}/#{resolution}/#{DateTime.to_iso8601(bin)}"
end
