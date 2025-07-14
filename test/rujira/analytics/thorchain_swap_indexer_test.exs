defmodule Rujira.Analytics.Swap.IndexerTest do
  use Rujira.PublisherCase

  alias Rujira.Analytics.Swap.Indexer
  alias Rujira.Fixtures.Block

  test "Index swaps for analytics" do
    # PAY ATTENTION THIS IS A MAINNET BLOCK
    {:ok, block} = Block.load_block("21556309")

    Indexer.handle_new_block(block, nil)
  end
end
