defmodule Rujira.Merge.GrpcMock do
  @moduledoc """
  Mock adapter for GRPC client to simulate GRPC communication in tests.
  """

  @behaviour GRPC.Client.Adapter
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateResponse
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
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
    case request_mod.decode(request) do
      %QuerySmartContractStateRequest{
        address: "contract-merge",
        query_data: "{\"config\":{}}"
      } ->
        {:ok,
         %QuerySmartContractStateResponse{
           data:
             Jason.encode!(%{
               merge_denom: "gaia-kuji",
               merge_supply: "1000000000",
               ruji_denom: "rune",
               ruji_allocation: "10000000000",
               decay_starts_at: "1733424430000000000",
               decay_ends_at: "1764874030000000000"
             })
         }}
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
end
