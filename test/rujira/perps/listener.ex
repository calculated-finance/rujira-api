defmodule Rujira.Perps.ListenerTest do
  @moduledoc false
  use Rujira.PublisherCase

  alias Rujira.Fixtures.Block
  alias Rujira.Perps.Listener.Pool

  test "publishes Perps updates on block" do
    # 5368307 executes a deposit into the index vault yRune
    {:ok, block} = Block.load_block("5368307")

    Pool.handle_new_block(block, %{
      address: "sthor1f86r2e5kzlwf9dcq5f8frku5d39lhd3jc95juvs0ydrspqa49r4qua7xj4"
    })

    messages = wait_for_publishes(2)

    assert length(messages) == 2

    # 1 - Perps Pool Update
    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "PerpsPool:sthor1f86r2e5kzlwf9dcq5f8frku5d39lhd3jc95juvs0ydrspqa49r4qua7xj4"
                  )
              },
              [
                node:
                  Base.encode64(
                    "PerpsPool:sthor1f86r2e5kzlwf9dcq5f8frku5d39lhd3jc95juvs0ydrspqa49r4qua7xj4"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{contract: "sthor1f86r2e5kzlwf9dcq5f8frku5d39lhd3jc95juvs0ydrspqa49r4qua7xj4"},
              [
                perps_account_updated:
                  "sthor1f86r2e5kzlwf9dcq5f8frku5d39lhd3jc95juvs0ydrspqa49r4qua7xj4"
              ]}
           ]
  end
end
