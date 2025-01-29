defmodule Thorchain.Node.Grpc do
  require Logger
  use GenServer

  def start_link(grpcs) do
    GenServer.start_link(__MODULE__, Enum.shuffle(grpcs))
  end

  def init(grpcs) do
    Process.flag(:trap_exit, true)
    do_init(grpcs)
  end

  defp do_init([grpc | rest]) do
    case connect(grpc) do
      {:ok, connection} ->
        Logger.info("gRPC Connected to #{connection.host}")
        {:ok, connection}

      {:error, error} ->
        Logger.error("gRPC Failed for #{grpc}, #{error}")
        do_init(rest)
    end
  end

  defp do_init([]) do
    Logger.error("No available gRPC connections")
    {:stop, :no_connections}
  end

  def connect(addr) do
    if String.ends_with?(addr, ":443") do
      cred = GRPC.Credential.new(ssl: [verify: :verify_none])

      GRPC.Stub.connect(addr,
        interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
        cred: cred
      )
    else
      GRPC.Stub.connect(addr, interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}])
    end
  end

  def handle_info({:gun_down, _pid, _protocol, _message, _}, state) do
    {:stop, :normal, state}
  end

  def handle_call({:request, stub_fn, req}, _, channel) do
    case stub_fn.(channel, req) do
      {:ok, res} -> {:reply, {:ok, res}, channel}
      {:error, error} -> {:reply, {:error, error}, channel}
    end
  end
end
