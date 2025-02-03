defmodule Rujira.Repo.Migrations.UpdateSwapsSchema do
  use Ecto.Migration

  def change do
    rename table(:swaps), :emit_asset, to: :emit_asset_asset
    rename table(:swaps), :coin, to: :coin_asset

    alter table(:swaps) do
      remove :swap_target
      remove :swap_slip
      remove :liquidity_fee
      remove :pool_slip

      modify :liquidity_fee_in_rune, :bigint

      add :emit_asset_amount, :bigint
      add :coin_amount, :bigint

      add :volume_usd, :bigint
      add :liquidity_fee_in_usd, :bigint
      add :affiliate, :string
      add :affiliate_bps, :integer
      add :affiliate_fee_in_rune, :bigint
      add :affiliate_fee_in_usd, :bigint
    end
  end
end
