defmodule Thorchain.Node do
  use Supervisor
  require Logger

  @timeout 500

  def start_link(opts \\ []) do
    Logger.info("Starting link ")
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    websocket_endpoint = Application.fetch_env!(:rujira, Thorchain.Node)[:websocket]
    subscriptions = Application.fetch_env!(:rujira, Thorchain.Node)[:subscriptions]
    grpc_list = Application.fetch_env!(:rujira, Thorchain.Node)[:grpcs]
    pubsub = Application.get_env(:rujira, :pubsub, Rujira.PubSub)

    children = [
      {Thorchain.Node.Websocket,
       websocket: websocket_endpoint,
       subscriptions: subscriptions,
       pubsub: pubsub},
       :poolboy.child_spec(
        :grpc,
        [
          name: {:local, :grpc},
          worker_module: Thorchain.Node.Grpc,
          size: length(grpc_list) * 10,
          max_overflow: 5
        ],
        grpc_list
      )
    ]

    Supervisor.init(children, strategy: :one_for_one, name: Rujira.Supervisor)
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
