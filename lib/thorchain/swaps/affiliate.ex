defmodule Thorchain.Swaps.Affiliate do
  @moduledoc "Normalized affiliate data, supports 1:N per swap"

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "thorchain_affiliate_txs" do
    field :affiliate, :string, primary_key: true
    field :height, :integer, primary_key: true
    field :tx_idx, :integer, primary_key: true
    field :idx, :integer, primary_key: true

    field :affiliate_bps, :integer
    field :affiliate_fee_in_rune, :integer
    field :affiliate_fee_in_usd, :integer

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(affiliate, params) do
    affiliate
    |> cast(params, [
      :affiliate,
      :height,
      :tx_idx,
      :idx,
      :affiliate_bps,
      :affiliate_fee_in_rune,
      :affiliate_fee_in_usd
    ])
    |> validate_required([
      :affiliate,
      :height,
      :tx_idx,
      :idx,
      :affiliate_bps,
      :affiliate_fee_in_rune,
      :affiliate_fee_in_usd
    ])
    |> unique_constraint([:height, :tx_idx, :idx, :affiliate],
      name: "thorchain_affiliate_txs_pkey"
    )
  end
end
