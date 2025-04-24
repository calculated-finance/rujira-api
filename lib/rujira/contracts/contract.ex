defmodule Rujira.Contracts.Contract do
  import Ecto.Changeset
  use Ecto.Schema

  @modules :rujira
           |> Application.compile_env(__MODULE__, modules: [Rujira.Fin])
           |> Keyword.get(:modules)

  @primary_key false
  schema "contracts" do
    field :id, :string, primary_key: true
    field :module, Ecto.Enum, values: @modules
  end

  def changeset(contract, attrs) do
    contract
    |> cast(attrs, [:id, :module])
    |> validate_required([:id, :module])
    |> unique_constraint([:id])
  end
end
