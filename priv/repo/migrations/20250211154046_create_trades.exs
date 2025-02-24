defmodule Rujira.Repo.Migrations.CreateTrades do
  use Ecto.Migration

  def change do
    create table(:trades) do
      add :height, :integer, null: false
      add :tx_idx, :integer, null: false
      add :idx, :integer, null: false

      add :contract, :string, null: false
      add :txhash, :string, null: false
      add :offer, :bigint, null: false
      add :bid, :bigint, null: false
      add :rate, :decimal, null: false
      add :side, :string, null: false
      add :protocol, :string, null: false
      add :timestamp, :utc_datetime_usec, null: false
    end

    create index(:trades, :contract)
    create index(:trades, :side)
    create unique_index(:trades, [:height, :tx_idx, :idx], name: :trades_key)
  end
end
