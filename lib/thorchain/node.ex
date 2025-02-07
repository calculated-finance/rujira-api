defmodule Thorchain.Node do
  use Supervisor
  require Logger

  @timeout 5000
  @pool_name :grpc_pool

  def start_link(_opts \\ []) do
    Logger.info("Starting link ")
    Supervisor.start_link(__MODULE__, Application.get_env(:rujira, __MODULE__), name: __MODULE__)
  end

  @impl true
  def init(x) do
    websocket = Keyword.get(x, :websocket, "")
    api = Keyword.get(x, :api, "")
    grpcs = Keyword.get(x, :grpcs, [])
    size = Keyword.get(x, :size, 2)
    pubsub = Application.get_env(:rujira, :pubsub, Rujira.PubSub)

    poolboy_config = [
      {:name, {:local, @pool_name}},
      {:worker_module, __MODULE__.Grpc},
      {:size, size},
      {:max_overflow, 2},
      {:restart, :transient}
    ]

    children = [
      :poolboy.child_spec(@pool_name, poolboy_config, grpcs),
      {__MODULE__.Websocket, websocket: websocket, pubsub: pubsub, api: api}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def subscribe(topic) do
    pubsub = Application.get_env(:rujira, :pubsub, Rujira.PubSub)
    Phoenix.PubSub.subscribe(pubsub, topic)
  end

  def stub(stub_fn, req) do
    :poolboy.transaction(@pool_name, fn worker_pid ->
      GenServer.call(worker_pid, {:request, stub_fn, req}, @timeout)
    end)
  end
end
