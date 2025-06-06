defmodule Thornode do
  use Supervisor
  require Logger

  @pool Application.compile_env(__MODULE__, :pool, Thornode.Pool)
  @socket Application.compile_env(__MODULE__, :socket, Thornode.Websocket)

  def start_link(_opts \\ []) do
    Logger.info("Starting link ")
    config = Application.get_env(:rujira, __MODULE__)
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    Supervisor.init([{@pool, config}, {@socket, config}],
      strategy: :one_for_one
    )
  end

  defdelegate subscribe(topic), to: @socket
  defdelegate query(query_fn, req), to: @pool
end
