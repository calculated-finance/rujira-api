defmodule Rujira.Bow.ListenerTest do
  use ExUnit.Case
  import Mox

  alias Rujira.Fixtures.Block

  setup :verify_on_exit!

  defp collect_publishes(acc \\ []) do
    receive do
      {:published, _endpoint, _payload, _topics} = msg ->
        collect_publishes([msg | acc])
    after
      0 ->
        Enum.reverse(acc)
    end
  end

  test "Bow listener publishes account and pool update on bow deposit" do
    expect(Rujira.Events.PublisherMock, :publish, 4, fn endpoint, payload, topics ->
      send(self(), {:published, endpoint, payload, topics})
      :ok
    end)

    {:ok, block} = Block.load_block("bow")
    Rujira.Bow.Listener.handle_info(block, nil)

    messages = collect_publishes()

    # 4 messages: 2 BowAccount, 1 BowPoolXyk, 1 FinBook
    assert length(messages) == 4

    # Assert published messages
    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "BowPoolXyk:sthor1rh0z23g5m6nd7ja98yn7hkeuavqqpd77fxakgzz4w3635jgksy0qdetur3"
                  )
              },
              [
                node:
                  Base.encode64(
                    "BowPoolXyk:sthor1rh0z23g5m6nd7ja98yn7hkeuavqqpd77fxakgzz4w3635jgksy0qdetur3"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "FinBook:sthor1rh0z23g5m6nd7ja98yn7hkeuavqqpd77fxakgzz4w3635jgksy0qdetur3"
                  )
              },
              [
                node:
                  Base.encode64(
                    "FinBook:sthor1rh0z23g5m6nd7ja98yn7hkeuavqqpd77fxakgzz4w3635jgksy0qdetur3"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "BowAccount:sthor1t4gsjfs8q8j3mw2e402r8vzrtaslsf5re3ktut/x/bow-xyk-x/ruji-rune"
                  )
              },
              [
                node:
                  Base.encode64(
                    "BowAccount:sthor1t4gsjfs8q8j3mw2e402r8vzrtaslsf5re3ktut/x/bow-xyk-x/ruji-rune"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "BowAccount:sthor18afpdapfxxlvxcf95a3rd6p0fsw37mnfqj8aly/x/bow-xyk-x/ruji-rune"
                  )
              },
              [
                node:
                  Base.encode64(
                    "BowAccount:sthor18afpdapfxxlvxcf95a3rd6p0fsw37mnfqj8aly/x/bow-xyk-x/ruji-rune"
                  )
              ]}
           ]
  end
end
