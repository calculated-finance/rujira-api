defmodule Rujira.Repo.Migrations.CreateTorCandles do
  use Ecto.Migration

  def change do
    create table(:thorchain_tor_candles, primary_key: false) do
      add :id, :string, null: false
      add :asset, :string, primary_key: true
      add :resolution, :string, primary_key: true
      add :bin, :utc_datetime, primary_key: true
      add :high, :decimal, null: false
      add :low, :decimal, null: false
      add :open, :decimal, null: false
      add :close, :decimal, null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
