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
    field :liquidity_fee_in_rune, :integer
    field :liquidity_fee_in_usd, :integer

    field :emit_asset_asset, :string
    field :emit_asset_amount, :integer

    field :streaming_swap_quantity, :integer
    field :streaming_swap_count, :integer
    field :id, :string
    field :chain, :string
    field :from, :string
    field :to, :string
    field :coin_asset, :string
    field :coin_amount, :integer

    field :memo, :string
    field :timestamp, :utc_datetime_usec

    field :volume_usd, :integer

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(swap, params) do
    swap
    |> cast(params, [
      :height,
      :tx_idx,
      :idx,
      :pool,
      :liquidity_fee_in_rune,
      :liquidity_fee_in_usd,
      :emit_asset_asset,
      :emit_asset_amount,
      :streaming_swap_quantity,
      :streaming_swap_count,
      :id,
      :chain,
      :from,
      :to,
      :coin_asset,
      :coin_amount,
      :memo,
      :timestamp,
      :volume_usd
    ])
    |> validate_required([
      :height,
      :tx_idx,
      :idx,
      :pool,
      :liquidity_fee_in_rune,
      :liquidity_fee_in_usd,
      :emit_asset_asset,
      :emit_asset_amount,
      :id,
      :chain,
      :from,
      :to,
      :coin_asset,
      :coin_amount,
      :memo,
      :timestamp,
      :volume_usd
    ])
    |> unique_constraint([:height, :tx_idx, :idx], name: "swaps_pkey")
  end
end
