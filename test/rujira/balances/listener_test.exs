defmodule Rujira.Balances.ListenerTest do
  use Rujira.PublisherCase

  alias Rujira.Fixtures.Block

  test "publishes account update" do

    {:ok, block} = Block.load_block("4539686")
    Rujira.Balances.Listener.handle_info(block, nil)

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
