defmodule Rujira.Contracts.Contract do
  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:address, :binary_id, autogenerate: false}
  schema "contracts" do
    field :module, Ecto.Enum,
      values: [
        Rujira.Bow.Xyk,
        Rujira.Fin.Pair,
        Rujira.Merge.Pool,
        Rujira.Staking.Pool
      ]
  end

  def changeset(contract, attrs) do
    contract
    |> cast(attrs, [:module])
    |> validate_required([:module])
  end
end
