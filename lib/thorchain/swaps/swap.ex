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
    field :liquidity_fee_in_rune, :string
    field :liquidity_fee_in_usd, :string
    field :emit_asset, :string
    field :streaming_swap_quantity, :string
    field :streaming_swap_count, :string
    field :id, :string
    field :chain, :string
    field :from, :string
    field :to, :string
    field :coin, :string
    field :memo, :string
    field :timestamp, :utc_datetime_usec
    field :volume_usd, :string
    field :affiliate, :string
    field :affiliate_bps, :string
    field :affiliate_fee_in_rune, :string
    field :affiliate_fee_in_usd, :string

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
      :emit_asset,
      :streaming_swap_quantity,
      :streaming_swap_count,
      :id,
      :chain,
      :from,
      :to,
      :coin,
      :memo,
      :timestamp,
      :volume_usd,
      :liquidity_fee_in_usd,
      :affiliate,
      :affiliate_bps,
      :affiliate_fee_in_rune,
      :affiliate_fee_in_usd
    ])
    |> validate_required([
      :height,
      :tx_idx,
      :idx,
      :pool,
      :liquidity_fee_in_rune,
      :emit_asset,
      :streaming_swap_quantity,
      :streaming_swap_count,
      :id,
      :chain,
      :from,
      :to,
      :coin,
      :memo,
      :timestamp,
      :volume_usd,
      :liquidity_fee_in_usd
    ])
    |> unique_constraint([:height, :tx_idx, :idx], name: "swaps_pkey")
  end
end
