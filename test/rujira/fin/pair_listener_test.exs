defmodule Rujira.Fin.Listener.PairTest do
  use Rujira.PublisherCase

  alias Rujira.Fin.Listener.Pair
  alias Rujira.Fixtures.Block

  test "publishes Fin Book and Order updates on trade" do
    # 4539686 executes a trade on the ruji - usdt book sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5
    # it should publish a FinBook update
    # it should publish an Order filled update
    {:ok, block} = Block.load_block("4539686")
    Pair.handle_new_block(block, nil)

    messages = wait_for_publishes(1)
    assert length(messages) == 1

    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "FinBook:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5"
                  )
              },
              [
                node:
                  Base.encode64(
                    "FinBook:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5"
                  )
              ]}
           ]
  end
end
