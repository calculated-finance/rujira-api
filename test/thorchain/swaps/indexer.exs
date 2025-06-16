defmodule Thorchain.Swaps.IndexerTest do
  use Rujira.PublisherCase

  alias Rujira.Fixtures.Block

  test "indexing thorchain swaps with affiliate" do
    # last swap in this block has rj as affiliate
    # PAY ATTENTION THIS IS A MAINNET BLOCK
    {:ok, block} = Block.load_block("21556309")
    Thorchain.Swaps.Indexer.handle_new_block(block, nil)

    swaps =
      Thorchain.Swaps.list_swaps()

    assert length(swaps) == 5

    [swap | _] = Enum.reverse(swaps)
    assert swap.affiliate == "rj"
  end
end
