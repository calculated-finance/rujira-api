defmodule Rujira.Repo.Migrations.Contract do
  use Ecto.Migration

  def change do
    create table(:contracts, primary_key: false) do
      add :address, :string, primary_key: true
      add :module, :string
    end

    create index(:contracts, [:module])
  end
end
