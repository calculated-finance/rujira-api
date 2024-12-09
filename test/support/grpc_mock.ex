defmodule Rujira.GrpcMock do
  @moduledoc """
  Mock adapter for GRPC client to simulate GRPC communication in tests.
  """

  @behaviour GRPC.Client.Adapter
  alias GRPC.Client.Stream

  @impl true
  @spec connect(any(), any()) :: {:ok, any()}
  def connect(conn, _opts) do
    {:ok, conn}
  end

  @impl true
  def disconnect(channel) do
    {:ok, channel}
  end

  @impl true
  def send_request(%Stream{} = stream, content, _opts) do
    Stream.put_payload(stream, :request, content)
  end

  @impl true
  def receive_data(
        %Stream{request_mod: request_mod, payload: %{request: request}},
        _opts
      ) do
    data_mock = get_data_mock()

    case request_mod.decode(request) do
      request ->
        data_mock.get_response(request)
    end
  end

  @impl true
  def send_headers(stream, _opts) do
    stream
  end

  @impl true
  def send_data(stream, _msg, _opts) do
    stream
  end

  @impl true
  def end_stream(stream) do
    stream
  end

  @impl true
  def cancel(_stream) do
    :ok
  end

  defp get_data_mock do
    Application.get_env(:rujira, :grpc_mock_data_module)
  end
end
