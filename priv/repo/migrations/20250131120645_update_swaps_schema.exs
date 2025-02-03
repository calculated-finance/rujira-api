defmodule Rujira.Repo.Migrations.UpdateSwapsSchema do
  use Ecto.Migration

  def change do
    alter table(:swaps) do
      remove :swap_target, :string
      remove :swap_slip, :string
      remove :liquidity_fee, :string
      remove :pool_slip, :string

      modify :liquidity_fee_in_rune, :string
      modify :streaming_swap_quantity, :string
      modify :streaming_swap_count, :string

      add :volume_usd, :string
      add :liquidity_fee_in_usd, :string
      add :affiliate, :string
      add :affiliate_bps, :string
      add :affiliate_fee_in_rune, :string
      add :affiliate_fee_in_usd, :string
    end

    execute """
    UPDATE swaps
    SET
      liquidity_fee_in_rune = liquidity_fee_in_rune::text,
      streaming_swap_quantity = streaming_swap_quantity::text,
      streaming_swap_count = streaming_swap_count::text
    """
  end
end
