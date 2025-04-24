defmodule Rujira.Repo.Migrations.ContractInfos do
  use Ecto.Migration

  def change do
    create table(:contract_infos) do
      add :id, :string, primary_key: true
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
    create unique_index(:contract_infos, [:id])
  end
end
