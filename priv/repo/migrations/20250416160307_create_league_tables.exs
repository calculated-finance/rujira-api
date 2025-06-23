defmodule Rujira.Repo.Migrations.CreateLeagueTables do
  use Ecto.Migration

  def change do
    create table(:league_tx_events) do
      add :height, :integer, null: false
      add :idx, :integer, null: false
      add :txhash, :string, null: false
      add :timestamp, :utc_datetime, null: false
      add :address, :string, null: false
      add :revenue, :bigint, null: false
      add :category, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:league_tx_events, [:height, :idx, :txhash], name: :league_tx_events_key)
    create index(:league_tx_events, [:address])
    create index(:league_tx_events, [:timestamp])
    create index(:league_tx_events, [:category])

    create table(:league_events) do
      add :league, :string, null: false
      add :season, :integer, null: false
      add :points, :bigint, null: false
      add :tx_event_id, references(:league_tx_events, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:league_events, [:tx_event_id, :league, :season],
             name: :league_events_key
           )

    create index(:league_events, [:league, :season])
    create index(:league_events, [:tx_event_id])
  end
end
