defmodule Thorchain.Node do
  use Supervisor
  require Logger

  @timeout 500

  def start_link(opts \\ []) do
    Logger.info("Starting link ")
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(x) do
    websocket_endpoint = Keyword.get(x, :websocket, "")
    subscriptions = Keyword.get(x, :subscriptions, [])
    grpc_list = Keyword.get(x, :grpcs, [])

    []
    |> add_grpcs(grpc_list)
    |> add_websocket(websocket_endpoint, subscriptions)
    |> Supervisor.init(strategy: :one_for_one, name: Rujira.Supervisor)
  end

  def add_grpcs(children, []) do
    children
  end

  def add_grpcs(children, grpcs) do
    [
      :poolboy.child_spec(
        :grpc,
        [
          name: {:local, :grpc},
          worker_module: Thorchain.Node.Grpc,
          size: length(grpcs) * 10,
          max_overflow: 5
        ],
        grpcs
      )
      | children
    ]
  end

  def add_websocket(children, "", _) do
    children
  end

  def add_websocket(children, websocket, subscriptions) do
    pubsub = Application.get_env(:rujira, :pubsub, Rujira.PubSub)

    [
      {Thorchain.Node.Websocket,
       websocket: websocket, subscriptions: subscriptions, pubsub: pubsub}
      | children
    ]
  end

  def subscribe(topic) do
    pubsub = Application.get_env(:rujira, :pubsub, Rujira.PubSub)
    Phoenix.PubSub.subscribe(pubsub, topic)
  end

  def stub(stub_fn, req) do
    :poolboy.transaction(:grpc, fn worker_pid ->
      try do
        with {:ok, channel} <- GenServer.call(worker_pid, :channel, @timeout) do
          stub_fn.(channel, req)
        end
      catch
        :error, _ ->
          reconnect_and_retry(worker_pid, stub_fn, req)
      end
    end)
  end

  defp reconnect_and_retry(worker_pid, stub_fn, req) do
    with {:ok, _} <- GenServer.call(worker_pid, :reconnect, @timeout) do
      stub(stub_fn, req)
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
