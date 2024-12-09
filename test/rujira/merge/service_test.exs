defmodule Rujira.Merge.ServiceTest do
  use ExUnit.Case, async: true

  alias Rujira.Merge.Service
  alias Rujira.Merge.Pool
  alias Rujira.Merge.Account

  use Rujira.TestHelpers

  # setup :verify_on_exit!

  describe "test_conn/0" do
    test "connects using the mock", %{channel: channel} do

      # Access the channel set up by TestHelpers
      res = Rujira.Contract.query_state_smart(channel, "", %{config: %{}})

      assert res == %GRPC.Channel{}
    end
  end
end
