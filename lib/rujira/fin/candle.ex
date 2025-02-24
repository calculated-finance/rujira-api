defmodule Rujira.Fin.Candle do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "candles" do
    field :id, :string, virtual: true

    field :contract, :string, primary_key: true
    field :resolution, :string, primary_key: true
    field :bin, :utc_datetime, primary_key: true

    field :close, :decimal
    field :high, :decimal
    field :low, :decimal
    field :open, :decimal
    field :volume, :integer

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(candle, attrs) do
    candle
    |> cast(attrs, [:contract, :resolution, :bin, :high, :low, :open, :close, :volume])
    |> validate_required([:contract, :resolution, :bin, :high, :low, :open, :close, :volume])
  end
end
