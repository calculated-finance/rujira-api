defmodule Rujira.Repo.Migrations.IndexNavBinTvl do
  use Ecto.Migration

  def change do
    alter table(:index_nav_bins) do
      add :tvl, :bigint, default: 0
    end
  end
end
