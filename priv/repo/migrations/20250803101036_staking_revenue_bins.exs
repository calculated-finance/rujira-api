defmodule Rujira.Repo.Migrations.StakingRevenueBins do
  use Ecto.Migration

  def change do
    create table("rujira_analytics_staking_revenue_bins", primary_key: false) do
      add :id, :string

      add :resolution, :string, primary_key: true
      add :bin, :utc_datetime, primary_key: true
      add :contract, :string, primary_key: true

      add :lp_weight, :decimal

      add :total_revenue, :bigint
      add :liquid_revenue, :bigint
      add :account_revenue, :bigint

      add :total_balance, :bigint
      add :liquid_balance, :bigint
      add :account_balance, :bigint

      add :total_value, :bigint
      add :liquid_value, :bigint
      add :account_value, :bigint

      add :account_apr, :decimal
      add :account_revenue_per_share, :decimal

      add :liquid_redemption_rate_start, :decimal
      add :liquid_redemption_rate_current, :decimal
      add :liquid_apy, :decimal

      add :account_inflows, :bigint
      add :account_outflows, :bigint
      add :liquid_inflows, :bigint
      add :liquid_outflows, :bigint

      timestamps(type: :utc_datetime_usec)
    end

    create index("rujira_analytics_staking_revenue_bins", [:resolution])
    create index("rujira_analytics_staking_revenue_bins", [:bin])
    create index("rujira_analytics_staking_revenue_bins", [:contract])
    create unique_index("rujira_analytics_staking_revenue_bins", [:contract, :resolution, :bin])
  end
end
