defmodule Rujira.Repo.Migrations.AddIndexesToSwaps do
  use Ecto.Migration

  def change do
    create index(:swaps, [:timestamp])
    create index(:swaps, [:affiliate])
  end
end
