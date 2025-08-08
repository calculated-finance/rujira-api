defmodule Rujira.Pilot.IndexerTest do
  use Rujira.PublisherCase

  alias Rujira.Fixtures.Block
  alias Rujira.Pilot.Indexer

  test "publishes PilotBidPools update and single pilot order" do
    {:ok, block} = Block.load_block("5011653")

    Indexer.handle_new_block(block, nil)

    messages = wait_for_publishes(2)

    assert length(messages) == 2
  end
end
