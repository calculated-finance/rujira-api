defmodule Rujira.Repo.Migrations.Contract do
  use Ecto.Migration

  def change do
    create table(:contracts, primary_key: false) do
      add :id, :string, primary_key: true
      add :field, :string, primary_key: true
      add :module, :string
    end

    create unique_index(:contracts, [:id, :field])
    create index(:contracts, [:module])
  end
end
