defmodule Rujira.Leagues.TxEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @categories [:swap, :trade]

  @type t :: %__MODULE__{
          id: integer(),
          height: non_neg_integer(),
          idx: non_neg_integer(),
          txhash: String.t(),
          timestamp: DateTime.t(),
          address: String.t(),
          revenue: non_neg_integer(),
          category: String.t()
        }

  schema "league_tx_events" do
    field :height, :integer
    field :idx, :integer
    field :txhash, :string
    field :timestamp, :utc_datetime_usec

    field :address, :string
    field :revenue, :integer

    field :category, Ecto.Enum, values: @categories

    has_many :events, Rujira.Leagues.Event

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(tx_event, params) do
    tx_event
    |> cast(params, [:height, :idx, :txhash, :timestamp, :address, :revenue, :category])
    |> validate_required([:height, :idx, :txhash, :timestamp, :address, :revenue, :category])
    |> unique_constraint([:height, :idx, :txhash], name: :league_tx_events_key)
  end
end
