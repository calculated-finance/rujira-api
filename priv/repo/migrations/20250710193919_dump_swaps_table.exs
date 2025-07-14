defmodule Rujira.Repo.Migrations.DropSwapsTables do
  use Ecto.Migration

  def change do
    drop table(:thorchain_affiliate_txs)
    drop table(:swaps)
  end
end
