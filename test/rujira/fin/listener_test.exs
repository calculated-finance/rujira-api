defmodule Rujira.Fin.ListenerTest do
  use Rujira.PublisherCase

  alias Rujira.Fin.Listener
  alias Rujira.Fixtures.Block

  test "publishes Fin Book and Order updates on trade" do
    # 4539686 executes a trade on the ruji - usdt book sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5
    # it should publish a FinBook update
    # it should publish an Order filled update
    {:ok, block} = Block.load_block("4539686")
    Listener.handle_new_block(block, nil)

    messages = wait_for_publishes(2)
    assert length(messages) == 2

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
              ]},
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

  test "publishes Fin Book updates on Bow actions" do
    # 4541708 executes a Bow action on the ruji - rune xyk mm
    # it should publish a FinBook update on the ruji - rune fin pair
    # sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r
    {:ok, block} = Block.load_block("4541708")
    Listener.handle_new_block(block, nil)

    messages = wait_for_publishes(1)
    assert length(messages) == 1

    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "FinBook:sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r"
                  )
              },
              [
                node:
                  Base.encode64(
                    "FinBook:sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r"
                  )
              ]}
           ]
  end

  test "published events on Order Created and Order Filled" do
    # 4574056 executes a Fin Order Created on the ruji - rune pair
    {:ok, block} = Block.load_block("4574056")
    Listener.handle_new_block(block, nil)

    messages = wait_for_publishes(2)
    assert length(messages) == 2

    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "FinBook:sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r"
                  )
              },
              [
                node:
                  Base.encode64(
                    "FinBook:sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r"
                  )
              ]},
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
    Listener.handle_new_block(block, nil)

    filled_messages = wait_for_publishes(2)
    assert length(filled_messages) == 2

    assert filled_messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "FinBook:sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r"
                  )
              },
              [
                node:
                  Base.encode64(
                    "FinBook:sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r"
                  )
              ]},
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
end
