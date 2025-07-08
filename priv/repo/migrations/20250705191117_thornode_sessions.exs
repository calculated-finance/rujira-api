defmodule Rujira.Repo.Migrations.ThornodeSessions do
  use Ecto.Migration

  def change do
    create table(:thornode_sessions) do
      add :start_height, :integer, null: false
      add :checkpoint_height, :integer, null: false
      add :backfill_height, :integer
      add :restart_height, :integer
      add :status, :string, null: false

      timestamps()
    end

    create index(:thornode_sessions, [:status])
  end
end
