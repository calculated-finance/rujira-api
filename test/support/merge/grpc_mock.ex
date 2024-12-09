defmodule Rujira.Merge.GrpcMock do
  @moduledoc """
  Mock adapter for GRPC client to simulate GRPC communication in tests.
  """

  alias GRPC.Client.Stream
  alias GRPC.Channel

  @behaviour GRPC.Client.Adapter

  @impl true
  def connect(channel, _opts) do
    {:ok, channel}
  end

  @impl true
  def disconnect(channel) do
    GRPC.Stub.disconnect(channel)
  end

  @impl true
  def send_request(stream, contents, opts) do
    IO.inspect(stream, label: "Mocked send_request stream")
    IO.inspect(contents, label: "Mocked send_request contents")
    IO.inspect(opts, label: "Mocked send_request opts")

    {:ok, stream}
  end

  @impl true
  def receive_data(stream, opts) do
    IO.inspect(stream, label: "Mocked receive_data stream")
    IO.inspect(opts, label: "Mocked receive_data opts")
    {:ok, "whatever"}
  end

  @impl true
  def cancel(stream) do
    IO.inspect(stream, label: "Mocked cancel")
    :ok
  end

  @impl true
  def end_stream(stream) do
    IO.inspect(stream, label: "Mocked end_stream")
    :ok
  end

  @impl true
  def send_data(stream, data, opts) do
    IO.inspect(stream, label: "Mocked send_data stream")
    IO.inspect(data, label: "Mocked send_data data")
    IO.inspect(opts, label: "Mocked send_data opts")

    {:ok, data}
  end

  @impl true
  def send_headers(stream, headers) do
    IO.inspect(stream, label: "Mocked send_headers stream")
    IO.inspect(headers, label: "Mocked send_headers headers")

    :ok
  end
end
