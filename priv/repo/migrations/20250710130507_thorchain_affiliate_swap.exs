defmodule Rujira.Repo.Migrations.ThorchainAffiliateSwap do
  use Ecto.Migration

  def change do
    create table(:thorchain_affiliate_txs, primary_key: false) do
      add :affiliate, :string, primary_key: true
      add :height, :bigint, primary_key: true
      add :tx_idx, :integer, primary_key: true
      add :idx, :integer, primary_key: true
      add :affiliate_bps, :integer, null: false
      add :affiliate_fee_in_rune, :bigint, null: false
      add :affiliate_fee_in_usd, :bigint, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:thorchain_affiliate_txs, [:affiliate])
    create index(:thorchain_affiliate_txs, [:height, :tx_idx, :idx])
  end
end
