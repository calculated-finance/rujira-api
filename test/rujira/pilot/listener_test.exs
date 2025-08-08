defmodule Rujira.Pilot.ListenerTest do
  use Rujira.PublisherCase

  alias Rujira.Fixtures.Block
  alias Rujira.Pilot.Listener

  test "publishes PilotBidPools update and single pilot order" do
    {:ok, block} = Block.load_block("5011653")

    # query sales to see invalidation
    Rujira.Keiko.load_sales(nil, nil)

    Listener.handle_new_block(block, nil)

    messages = wait_for_publishes(3)

    assert length(messages) == 3

    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "PilotAccount:sthor196a6eckv2sayma3y2zykutvs226km3r0f4krv7nv0aeg090lsatq7l6ntu/sthor1w306fa945cmta2znkeej33246hxl69cmhj2z85"
                  )
              },
              [
                node:
                  Base.encode64(
                    "PilotAccount:sthor196a6eckv2sayma3y2zykutvs226km3r0f4krv7nv0aeg090lsatq7l6ntu/sthor1w306fa945cmta2znkeej33246hxl69cmhj2z85"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "PilotBidPools:sthor196a6eckv2sayma3y2zykutvs226km3r0f4krv7nv0aeg090lsatq7l6ntu"
                  )
              },
              [
                node:
                  Base.encode64(
                    "PilotBidPools:sthor196a6eckv2sayma3y2zykutvs226km3r0f4krv7nv0aeg090lsatq7l6ntu"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{
                premium: "3",
                contract: "sthor196a6eckv2sayma3y2zykutvs226km3r0f4krv7nv0aeg090lsatq7l6ntu"
              },
              [
                pilot_bid_updated: "sthor1w306fa945cmta2znkeej33246hxl69cmhj2z85"
              ]}
           ]
  end
end
