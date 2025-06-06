defmodule Rujira.Balances.ListenerTest do
  use ExUnit.Case, async: true
  import Mox
  setup :verify_on_exit!

  # test "publishes account update" do
  #   expect(Rujira.Events.PublisherMock, :publish, fn endpoint, payload, topics ->
  #     nil
  #     # assert endpoint == RujiraWeb.Endpoint
  #     # assert topics == [node: Base.encode64("Layer1Account:thor:foo")]
  #     # assert payload == %{id: Base.encode64("Layer1Account:thor:foo")}
  #   end)

  #   {:ok, block} = Thorchain.block("")
  #   Rujira.Balances.Listener.handle_info(block, nil)
  # end
end
