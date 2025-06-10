defmodule Rujira.Bank.TransferTest do
  use RujiraWeb.ConnCase

  alias Rujira.Fixtures.Block

  test "stores transfers" do
    {:ok, block} = Block.load_block("4539686")
    Rujira.Bank.Transfer.handle_info(block, nil)

    transfers = Rujira.Repo.all(Rujira.Bank.Transfer)
    assert length(transfers) > 0
  end
end
