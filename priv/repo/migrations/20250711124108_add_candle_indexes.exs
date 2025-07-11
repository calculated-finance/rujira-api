defmodule Rujira.Repo.Migrations.AddCandleIndexes do
  use Ecto.Migration
  @disable_migration_lock true
  @disable_ddl_transaction true
  def change do
    create index(:candles, [:id], concurrently: true)
    create index(:thorchain_tor_candles, [:id], concurrently: true)
  end
end
