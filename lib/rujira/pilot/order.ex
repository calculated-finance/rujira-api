defmodule Rujira.Pilot.BidAction do
  @moduledoc """
  Single bid action for a sale contract
  """
  use Ecto.Schema
  import Ecto.Changeset

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

  def changeset(bid_action, params) do
    bid_action
    |> cast(params, [
      :height,
      :tx_idx,
      :idx,
      :contract,
      :txhash,
      :owner,
      :premium,
      :amount,
      :type,
      :timestamp
    ])
    |> validate_required([
      :height,
      :tx_idx,
      :idx,
      :contract,
      :txhash,
      :owner,
      :premium,
      :amount,
      :type,
      :timestamp
    ])
    |> unique_constraint([:height, :tx_idx, :idx], name: :pilot_bid_actions_key)
  end
end
