defmodule Rujira.Balances.ListenerTest do
  use Rujira.PublisherCase

  alias Rujira.Balances.Listener
  alias Rujira.Fixtures.Block

  test "publishes account update" do
    {:ok, block} = Block.load_block("4539686")
    Listener.handle_new_block(block, nil)

    collect_publishes()
    |> Enum.each(fn
      {:published, endpoint, _, topics} ->
        assert endpoint == RujiraWeb.Endpoint
        node = topics[:node]
        decoded_id = Base.decode64!(node)
        [type, id, _] = String.split(decoded_id, ":")
        assert type == "Layer1Account"
        assert id == "thor"
    end)
  end
end
