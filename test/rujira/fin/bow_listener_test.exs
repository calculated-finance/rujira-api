defmodule Rujira.Fin.Listener.BowTest do
  use Rujira.PublisherCase

  alias Rujira.Fin.Listener.Bow
  alias Rujira.Fixtures.Block

  test "publishes Fin Book updates on Bow actions" do
    # 4541708 executes a Bow action on the ruji - rune xyk mm
    # it should publish a FinBook update on the ruji - rune fin pair
    # sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r
    {:ok, block} = Block.load_block("4541708")
    Bow.handle_new_block(block, nil)

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
end
