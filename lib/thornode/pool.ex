defmodule Thornode.Pool do
  @moduledoc """
  Manages a pool of gRPC worker processes for communicating with the Thorchain node.
  """

  use Supervisor
  require Logger

  @timeout 5000
  @pool_name :grpc_pool

  def start_link(opts \\ []) do
    Logger.info("Starting Thornode.Pool link")
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    config = opts
    grpcs = Keyword.get(config, :grpcs, [])
    size = Keyword.get(config, :size, 2)

    poolboy_config = [
      name: {:local, @pool_name},
      worker_module: Thornode.Worker,
      size: size,
      max_overflow: 2,
      strategy: :fifo
    ]

    children = [:poolboy.child_spec(@pool_name, poolboy_config, grpcs)]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def query(query_fn, req) do
    :poolboy.transaction(@pool_name, fn worker_pid ->
      GenServer.call(worker_pid, {:request, query_fn, req}, @timeout)
    end)
  end
end
