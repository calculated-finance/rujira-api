defmodule Rujira.Repo.Migrations.AnalyticsSwapTables do
  use Ecto.Migration

  def change do
    create table(:thorchain_swap_address_bins, primary_key: false) do
      add :resolution, :string, primary_key: true
      add :bin, :utc_datetime, primary_key: true
      add :affiliate, :string, primary_key: true
      add :address, :string, primary_key: true

      add :address_weight, :decimal

      timestamps(type: :utc_datetime_usec)
    end

    create table(:thorchain_swap_affiliate_bins, primary_key: false) do
      add :resolution, :string, primary_key: true
      add :bin, :utc_datetime, primary_key: true
      add :affiliate, :string, primary_key: true

      add :count, :decimal
      add :revenue, :bigint
      add :liquidity_fee, :bigint
      add :volume, :bigint

      timestamps(type: :utc_datetime_usec)
    end

    create table(:thorchain_swap_asset_bins, primary_key: false) do
      add :resolution, :string, primary_key: true
      add :bin, :utc_datetime, primary_key: true
      add :affiliate, :string, primary_key: true
      add :asset, :string, primary_key: true

      add :volume, :bigint

      timestamps(type: :utc_datetime_usec)
    end

    create table(:thorchain_swap_chain_bins, primary_key: false) do
      add :resolution, :string, primary_key: true
      add :bin, :utc_datetime, primary_key: true
      add :affiliate, :string, primary_key: true
      add :source_chain, :string, primary_key: true

      add :volume, :bigint

      timestamps(type: :utc_datetime_usec)
    end

    create index(:thorchain_swap_address_bins, [:address])
    create index(:thorchain_swap_affiliate_bins, [:affiliate])
    create index(:thorchain_swap_asset_bins, [:asset])
    create index(:thorchain_swap_chain_bins, [:source_chain])

    # resolution + bin indexes
    create index(:thorchain_swap_address_bins, [:resolution, :bin])
    create index(:thorchain_swap_affiliate_bins, [:resolution, :bin])
    create index(:thorchain_swap_asset_bins, [:resolution, :bin])
    create index(:thorchain_swap_chain_bins, [:resolution, :bin])

    create index(:thorchain_swap_address_bins, [:affiliate, :bin])
    create index(:thorchain_swap_affiliate_bins, [:affiliate, :bin])
    create index(:thorchain_swap_asset_bins, [:affiliate, :bin])
    create index(:thorchain_swap_chain_bins, [:affiliate, :bin])
  end
end
