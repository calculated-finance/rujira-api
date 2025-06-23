defmodule Rujira.Bank.SupplyTest do
  use ExUnit.Case
  alias Rujira.Bank.Supply
  alias Rujira.Fixtures.Block

  test "updates supply state" do
    {:ok, block} = Block.load_block("4539686")
    {:noreply, state} = Supply.handle_new_block(block, %{})

    assert state != %{}
  end
end
