defmodule Rujira.Balances.ListenerTest do
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

  test "publishes account update" do
    stub(Rujira.Events.PublisherMock, :publish, fn endpoint, payload, topics ->
      send(self(), {:published, endpoint, payload, topics})
      :ok
    end)

    {:ok, block} = Block.load_block("balances")
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
