defmodule Thorchain.Node do
  use Supervisor
  require Logger

  @timeout 500
  @pool_name :grpc_pool

  def start_link(opts \\ []) do
    Logger.info("Starting link ")
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(x) do
    websocket = Keyword.get(x, :websocket, "")
    grpcs = Keyword.get(x, :grpcs, [])
    pubsub = Application.get_env(:rujira, :pubsub, Rujira.PubSub)

    poolboy_config = [
      {:name, {:local, @pool_name}},
      {:worker_module, __MODULE__.Grpc},
      {:size, 2},
      {:max_overflow, 2}
    ]

    children = [
      :poolboy.child_spec(@pool_name, poolboy_config, grpcs),
      {__MODULE__.Websocket, websocket: websocket, pubsub: pubsub}
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
