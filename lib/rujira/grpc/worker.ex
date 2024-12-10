defmodule Rujira.Grpc.Worker do
  use GenServer

  def start_link(grpc_list) do
    GenServer.start_link(__MODULE__, grpc_list)
  end

  def init(grpc_list) do
    with {:ok, channel, new_grpc_list} <- connect(Enum.shuffle(grpc_list)) do
      {:ok, %{grpc_list: new_grpc_list, connected: channel}}
    end
  end

  # This is not good - gun goes up and down every second because i'm missing something
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_call(:channel, _from, %{connected: nil} = state) do
    {:reply, {:error, "GRPC connection not ready"}, state}
  end

  def handle_call(:channel, _from, %{connected: channel} = state) do
    {:reply, {:ok, channel}, state}
  end

  def handle_call(:reconnect, _from, %{grpc_list: grpc_list}) do
    with {:ok, channel, new_grpc_list} <- connect(Enum.shuffle(grpc_list)) do
      {:ok, %{grpc_list: new_grpc_list, connected: channel}}
    else
      {:error, reason} -> {:reply, {:error, reason}, %{grpc_list: grpc_list, connected: nil}}
    end
  end

  def handle_call(_request, _from, state) do
    {:reply, :ok, state}
  end

  def connect([%{host: host, port: port} = el | rest]) do
    cred = GRPC.Credential.new(ssl: [verify: :verify_none])

    case GRPC.Stub.connect(host, port,
           interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
           cred: cred
         ) do
      {:ok, channel} ->
        IO.puts("Successfully connected to GRPC server.")
        {:ok, channel, rest ++ [el]}

      {:error, _} ->
        IO.puts("Connection failed, trying next GRPC server...")
        connect(rest ++ [el])
    end
  end
end
