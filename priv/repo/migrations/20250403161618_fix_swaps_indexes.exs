defmodule Rujira.Repo.Migrations.FixSwapsIndexes do
  use Ecto.Migration

  def change do
    # Composite index on affiliate and timestamp to optimize filtering
    create index(:swaps, [:affiliate, :timestamp])

    # Index on pool to support grouping and joins by asset
    create index(:swaps, [:pool])

    # Index on chain to support grouping and joins by chain
    create index(:swaps, [:chain])

    # Index on from to optimize the DISTINCT count for unique swap users
    create index(:swaps, [:from])
  end
end
