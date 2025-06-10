defmodule Rujira.Bank.SupplyTest do
  use ExUnit.Case

  alias Rujira.Fixtures.Block


  test "updates supply state" do
    {:ok, block} = Block.load_block("4539686")
    {:noreply, state} = Rujira.Bank.Supply.handle_info(block, %{})

    assert state != %{}
  end
end
