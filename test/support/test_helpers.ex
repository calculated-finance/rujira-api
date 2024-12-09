defmodule Rujira.TestHelpers do
  defmacro __using__(_) do
    quote do
      setup do
        {:ok, channel} =
          GRPC.Stub.connect("", adapter: Rujira.Merge.GrpcMock)

        [channel: channel]
      end
    end
  end
end
