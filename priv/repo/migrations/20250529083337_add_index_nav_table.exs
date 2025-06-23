defmodule Rujira.Repo.Migrations.AddIndexNavTable do
  use Ecto.Migration

  def change do
    create table(:index_nav_bins, primary_key: false) do
      add :id, :string, null: false
      add :contract, :string, primary_key: true
      add :resolution, :string, primary_key: true
      add :bin, :utc_datetime, primary_key: true
      add :open, :decimal, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:index_nav_bins, [:contract, :resolution, :bin])
  end
end
