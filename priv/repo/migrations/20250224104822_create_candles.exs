defmodule Rujira.Repo.Migrations.CreateCandles do
  use Ecto.Migration

  def change do
    create table(:candles, primary_key: false) do
      add :contract, :string, primary_key: true
      add :resolution, :string, primary_key: true
      add :bin, :utc_datetime, primary_key: true
      add :high, :decimal
      add :low, :decimal
      add :open, :decimal
      add :close, :decimal
      add :volume, :bigint

      timestamps(type: :utc_datetime_usec)
    end
  end
end
