defmodule Rujira.Repo.Migrations.ContractInfos do
  use Ecto.Migration

  def change do
    create table(:contract_infos, primary_key: false) do
      add :address, :string, primary_key: true
      add :code_id, :bigint
      add :creator, :string
      add :admin, :string
      add :label, :string
      add :created, :map
      add :ibc_port_id, :string
      add :extension, :map

      timestamps()
    end

    create index(:contract_infos, [:code_id])
    create index(:contract_infos, [:admin])
    create index(:contract_infos, [:label])
  end
end
