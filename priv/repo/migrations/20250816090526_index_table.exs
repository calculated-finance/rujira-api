defmodule Rujira.Repo.Migrations.IndexTable do
  use Ecto.Migration

  def change do
    alter table(:index_nav_bins) do
      add :redemption_rate, :decimal, default: 1
    end
  end
end
