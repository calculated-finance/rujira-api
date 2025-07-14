defmodule Rujira.TestHelpers do
  @moduledoc false
  defmacro __using__(_) do
    caller_module = __CALLER__.module
    related_data_mock = infer_related_mock(caller_module)

    quote do
      setup do
        Rujira.CoingeckoMocks.mock_prices()
        Application.put_env(:rujira, :grpc_mock_data_module, unquote(related_data_mock))

        {:ok, channel} =
          GRPC.Stub.connect("", adapter: Rujira.GrpcMock)

        [channel: channel]
      end
    end
  end

  defp infer_related_mock(module) do
    module
    |> Module.split()
    |> Enum.drop(-1)
    |> List.insert_at(1, "DataMocks")
    |> Module.concat()
  end
end
