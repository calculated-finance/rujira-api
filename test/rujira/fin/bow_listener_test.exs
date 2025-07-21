defmodule Rujira.Fin.Listener.BowTest do
  use Rujira.PublisherCase

  alias Rujira.Fin.Listener.Bow
  alias Rujira.Fixtures.Block

  test "publishes Fin Book updates on Bow actions" do
    # 4541708 executes a Bow action on the ruji - rune xyk mm
    # it should publish a FinBook update on the ruji - rune fin pair
    # sthor1knzcsjqu3wpgm0ausx6w0th48kvl2wvtqzmvud4hgst4ggutehlseele4r
    {:ok, block} = Block.load_block("4541708")
    # use the Bow contract address
    Bow.handle_new_block(block, %{
      address: "sthor1rh0z23g5m6nd7ja98yn7hkeuavqqpd77fxakgzz4w3635jgksy0qdetur3"
    })

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
