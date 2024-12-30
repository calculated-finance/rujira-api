defmodule Thorchain.Swaps.Swap do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  A normalized Swap event. Primary key is on the (height, tx_idx, idx) tuple
  """

  @primary_key false
  schema "swaps" do
    field :height, :integer, primary_key: true
    field :tx_idx, :integer, primary_key: true
    field :idx, :integer, primary_key: true

    field :pool, :string
    field :swap_target, :integer
    field :swap_slip, :integer
    field :liquidity_fee, :integer
    field :liquidity_fee_in_rune, :integer
    field :emit_asset, :string
    field :streaming_swap_quantity, :integer
    field :streaming_swap_count, :integer
    field :pool_slip, :integer
    field :id, :string
    field :chain, :string
    field :from, :string
    field :to, :string
    field :coin, :string
    field :memo, :string
    field :timestamp, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(swap, params) do
    swap
    |> cast(params, [
      :height,
      :tx_idx,
      :idx,
      :pool,
      :swap_target,
      :swap_slip,
      :liquidity_fee,
      :liquidity_fee_in_rune,
      :emit_asset,
      :streaming_swap_quantity,
      :streaming_swap_count,
      :pool_slip,
      :id,
      :chain,
      :from,
      :to,
      :coin,
      :memo,
      :timestamp
    ])
    |> validate_required([
      :height,
      :tx_idx,
      :idx,
      :pool,
      :swap_target,
      :swap_slip,
      :liquidity_fee,
      :liquidity_fee_in_rune,
      :emit_asset,
      :streaming_swap_quantity,
      :streaming_swap_count,
      :pool_slip,
      :id,
      :chain,
      :from,
      :to,
      :coin,
      :memo,
      :timestamp
    ])
    |> unique_constraint([:height, :tx_idx, :idx], name: "swaps_pkey")
  end
end
