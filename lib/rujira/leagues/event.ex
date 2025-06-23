defmodule Rujira.Leagues.Event do
  @moduledoc """
  Defines the schema for league events and their associated points.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer(),
          league: String.t(),
          season: non_neg_integer(),
          points: non_neg_integer(),
          tx_event_id: integer(),
          tx_event: Rujira.Leagues.TxEvent.t()
        }

  schema "league_events" do
    field :league, :string
    field :season, :integer
    field :points, :integer

    belongs_to :tx_event, Rujira.Leagues.TxEvent

    timestamps()
  end

  def changeset(event, params) do
    event
    |> cast(params, [:league, :season, :points, :tx_event_id])
    |> validate_required([:league, :season, :points, :tx_event_id])
    |> assoc_constraint(:tx_event)
    |> unique_constraint([:tx_event_id, :league, :season], name: :league_events_key)
  end
end
