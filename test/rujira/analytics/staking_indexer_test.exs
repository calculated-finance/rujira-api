defmodule Rujira.Analytics.Staking.IndexerTest do
  use Rujira.PublisherCase

  alias Rujira.Analytics.Staking.Indexer
  alias Rujira.Analytics.Staking.RevenueBin
  alias Rujira.Fixtures.Block

  test "publishes account update" do
    {:ok, block} = Block.load_block("5334888")

    {:ok, pool} =
      Rujira.Staking.get_pool("sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj")

    Indexer.handle_new_block(block, pool)

    wait_for_publishes(3)

    RevenueBin
    |> Rujira.Repo.all()
  end
end
