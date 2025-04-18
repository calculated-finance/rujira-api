defmodule Rujira.Repo.Migrations.CreateBankTransfers do
  use Ecto.Migration

  def change do
    create table(:bank_transfers, primary_key: false) do
      add :height, :integer, primary_key: true
      add :event_idx, :integer, primary_key: true
      add :denom, :string, primary_key: true
      add :sender, :string, null: false
      add :recipient, :string, null: false
      add :amount, :bigint, null: false
      add :timestamp, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:bank_transfers, [:timestamp])
    create index(:bank_transfers, [:amount])
    create index(:bank_transfers, [:sender, :recipient, :denom])
    create index(:bank_transfers, [:recipient, :sender, :denom])
    create index(:bank_transfers, [:denom, :sender, :recipient])
    create index(:bank_transfers, [:denom, :recipient, :sender])
  end
end
