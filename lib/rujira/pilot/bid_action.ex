defmodule Rujira.Pilot.BidAction do
  @moduledoc """
  Single bid action for a sale contract
  """
  use Ecto.Schema

  schema "pilot_bid_actions" do
    field :height, :integer
    field :tx_idx, :integer
    field :idx, :integer

    field :contract, :string
    field :txhash, :string

    field :owner, :string
    field :premium, :integer
    field :amount, :integer
    field :type, Ecto.Enum, values: [:create, :retract, :increase, :withdraw]

    field :timestamp, :utc_datetime_usec
  end
end
