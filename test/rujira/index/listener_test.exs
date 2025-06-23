defmodule Rujira.Index.ListenerTest do
  use Rujira.PublisherCase

  alias Rujira.Fixtures.Block
  alias Rujira.Index.Listener

  test "publishes Index updates on block" do
    # 4576064 executes a deposit into the index vault yRune
    # it should publish an Index Vault update
    # it should publish an Index Account update
    {:ok, block} = Block.load_block("4576064")
    Listener.handle_new_block(block, nil)

    messages = collect_publishes()

    assert length(messages) == 4

    # 1 - Index Vault Update
    # 2 - Account Update deposit
    # 3 - Account Update minter
    # 4 - Account Update fee collector

    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "IndexVault:sthor1552fjtt2u6evfxwmnx0w68kh7u4fqt7e6vv0du3vj5rwggumy5jsmwzjsr"
                  )
              },
              [
                node:
                  Base.encode64(
                    "IndexVault:sthor1552fjtt2u6evfxwmnx0w68kh7u4fqt7e6vv0du3vj5rwggumy5jsmwzjsr"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "IndexAccount:sthor1g2rf7x4f9jxduz7ns9syzq4g8sqkp783d3jt0g/x/nami-index-nav-sthor1552fjtt2u6evfxwmnx0w68kh7u4fqt7e6vv0du3vj5rwggumy5jsmwzjsr-rcpt"
                  )
              },
              [
                node:
                  Base.encode64(
                    "IndexAccount:sthor1g2rf7x4f9jxduz7ns9syzq4g8sqkp783d3jt0g/x/nami-index-nav-sthor1552fjtt2u6evfxwmnx0w68kh7u4fqt7e6vv0du3vj5rwggumy5jsmwzjsr-rcpt"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "IndexAccount:sthor18afpdapfxxlvxcf95a3rd6p0fsw37mnfqj8aly/x/nami-index-nav-sthor1552fjtt2u6evfxwmnx0w68kh7u4fqt7e6vv0du3vj5rwggumy5jsmwzjsr-rcpt"
                  )
              },
              [
                node:
                  Base.encode64(
                    "IndexAccount:sthor18afpdapfxxlvxcf95a3rd6p0fsw37mnfqj8aly/x/nami-index-nav-sthor1552fjtt2u6evfxwmnx0w68kh7u4fqt7e6vv0du3vj5rwggumy5jsmwzjsr-rcpt"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "IndexAccount:sthor1q4xyrakn6kd3q43ezq7h43r57t57zs8qam5e0ts3tc06zvwlk60qrm6ecq/x/nami-index-nav-sthor1552fjtt2u6evfxwmnx0w68kh7u4fqt7e6vv0du3vj5rwggumy5jsmwzjsr-rcpt"
                  )
              },
              [
                node:
                  Base.encode64(
                    "IndexAccount:sthor1q4xyrakn6kd3q43ezq7h43r57t57zs8qam5e0ts3tc06zvwlk60qrm6ecq/x/nami-index-nav-sthor1552fjtt2u6evfxwmnx0w68kh7u4fqt7e6vv0du3vj5rwggumy5jsmwzjsr-rcpt"
                  )
              ]}
           ]
  end
end
