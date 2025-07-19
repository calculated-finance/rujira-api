defmodule Rujira.Fin.Listener.OrderTest do
  use Rujira.PublisherCase

  alias Rujira.Fin.Listener.Order
  alias Rujira.Fixtures.Block

  test "publishes Fin Book and Order updates on trade" do
    # 4539686 executes a trade on the ruji - usdt book sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5
    # it should publish a FinBook update
    # it should publish an Order filled update
    {:ok, block} = Block.load_block("4539686")

    Order.handle_new_block(block, %{
      address: "sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5"
    })

    messages = wait_for_publishes(1)
    assert length(messages) == 1

    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                price: "mm:0.885348892414736995",
                side: "quote"
              },
              [
                fin_order_filled:
                  "sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/quote/mm:0.885348892414736995"
              ]}
           ]
  end

  test "published events on Order Created and Order Filled" do
    # 4574056 executes a Fin Order Created on the ruji - rune pair
    {:ok, block} = Block.load_block("4574056")

    Order.handle_new_block(block, %{
      address: "sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r"
    })

    messages = wait_for_publishes(1)
    assert length(messages) == 1

    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                price: "fixed:1.012",
                side: "base",
                contract: "sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r"
              },
              [
                fin_order_updated: "sthor1t4gsjfs8q8j3mw2e402r8vzrtaslsf5re3ktut"
              ]}
           ]

    # fill the order on block 4574088
    {:ok, block} = Block.load_block("4574088")

    Order.handle_new_block(block, %{
      address: "sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r"
    })

    filled_messages = wait_for_publishes(1)
    assert length(filled_messages) == 1

    assert filled_messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                price: "fixed:1.012",
                side: "base"
              },
              [
                fin_order_filled:
                  "sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r/base/fixed:1.012"
              ]}
           ]
  end

  test "published events on Order Retracted" do
    # 21,998,339 executes a Fin Order Retracted on the ruji - rune pair
    # PAY ATTENTION THIS IS A MAINNET BLOCK
    Block.dump_block("21998339")
    {:ok, block} = Block.load_block("21998339")

    Order.handle_new_block(block, %{
      address: "thor17cawwg2lsnvcne69fek6nsqkf8snma6gc5ccceshul86rl0u3q4s5l5d0a"
    })

    messages = wait_for_publishes(1)
    assert length(messages) == 1

    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                price: "fixed:69",
                side: "base",
                contract: "thor17cawwg2lsnvcne69fek6nsqkf8snma6gc5ccceshul86rl0u3q4s5l5d0a"
              },
              [
                fin_order_updated: "thor1prlk9jmacfard72g96kuxmrqsvl3c6ftmte4q6"
              ]}
           ]
  end
end
