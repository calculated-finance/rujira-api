defmodule Rujira.Repo.Migrations.PilotOrders do
  use Ecto.Migration

  def change do
    create table(:pilot_bid_actions) do
      add :height, :integer
      add :tx_idx, :integer
      add :idx, :integer

      add :contract, :string
      add :txhash, :string

      add :owner, :string
      add :premium, :bigint
      add :amount, :bigint
      add :type, :string

      add :timestamp, :utc_datetime_usec
    end

    create index(:pilot_bid_actions, [:height, :tx_idx, :idx], unique: true)
    create index(:pilot_bid_actions, [:contract])
    create index(:pilot_bid_actions, [:owner])
  end
end
