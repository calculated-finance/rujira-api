defmodule Rujira.TestHelpers do
  defmacro __using__(_) do
    quote do
      setup do
        module_prefix = String.split(to_string(__MODULE__), ".") |> Enum.take(3) |> Enum.join(".")
        grpc_mock_module = Module.concat(module_prefix, ".GrpcMock")

        {:ok, channel} =
          GRPC.Stub.connect("thornode-devnet-grpc.bryanlabs.net", 443,
          interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
          adapter: grpc_mock_module
        )

        [channel: channel]
      end
    end
  end
end
