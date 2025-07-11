defmodule Thorchain.Swaps.IndexerTest do
  use Rujira.PublisherCase

  alias Rujira.Fixtures.Block
  alias Rujira.Repo
  alias Thorchain.Swaps
  alias Thorchain.Swaps.Affiliate
  alias Thorchain.Swaps.Indexer

  test "indexing thorchain swaps with affiliate" do
    # last swap in this block has rj as affiliate
    # PAY ATTENTION THIS IS A MAINNET BLOCK
    {:ok, block} = Block.load_block("21556309")
    Indexer.handle_new_block(block, nil)

    swaps =
      Swaps.list_swaps()

    affiliates = Repo.all(Affiliate)

    assert length(swaps) == 5

    [affiliate | _] = Enum.reverse(affiliates)
    assert affiliate.affiliate == "rj"
  end
end
