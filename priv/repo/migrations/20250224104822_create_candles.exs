defmodule Rujira.Repo.Migrations.CreateCandles do
  use Ecto.Migration

  def change do
    create table(:candles, primary_key: false) do
      add :id, :string, null: false
      add :contract, :string, primary_key: true
      add :resolution, :string, primary_key: true
      add :bin, :utc_datetime, primary_key: true
      add :high, :decimal, null: false
      add :low, :decimal, null: false
      add :open, :decimal, null: false
      add :close, :decimal, null: false
      add :volume, :bigint, null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
