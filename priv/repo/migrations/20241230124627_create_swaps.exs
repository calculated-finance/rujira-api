defmodule Rujira.Repo.Migrations.CreateSwaps do
  use Ecto.Migration

  def change do
    create table(:swaps, primary_key: false) do
      add :height, :integer, primary_key: true
      add :tx_idx, :integer, primary_key: true
      add :idx, :integer, primary_key: true

      add :pool, :string
      add :swap_target, :bigint
      add :swap_slip, :integer
      add :liquidity_fee, :bigint
      add :liquidity_fee_in_rune, :integer
      add :emit_asset, :string
      add :streaming_swap_quantity, :integer
      add :streaming_swap_count, :integer
      add :pool_slip, :integer
      add :id, :string
      add :chain, :string
      add :from, :string
      add :to, :string
      add :coin, :string
      add :memo, :string
      add :timestamp, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end
  end
end
