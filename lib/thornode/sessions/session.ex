defmodule Thornode.Session do
  @moduledoc """
  Thornode session tracking.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:current, :backfill, :completed]

  schema "thornode_sessions" do
    field :start_height, :integer
    field :checkpoint_height, :integer
    field :backfill_height, :integer
    field :restart_height, :integer
    field :status, Ecto.Enum, values: @statuses
    timestamps()
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [
      :start_height,
      :checkpoint_height,
      :backfill_height,
      :restart_height,
      :status
    ])
    |> validate_required([:start_height, :checkpoint_height, :status])
    |> validate_inclusion(:status, @statuses)
  end
end
