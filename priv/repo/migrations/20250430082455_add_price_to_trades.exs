defmodule Rujira.Repo.Migrations.AddPriceToTrades do
  use Ecto.Migration

  def change do
    alter table(:trades) do
      add :price, :string
    end

    create index(:trades, [:price])
  end
end
