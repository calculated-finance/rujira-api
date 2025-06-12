defmodule Thornode do
  use Supervisor
  require Logger

  @pool Thornode.Pool
  @socket Thornode.Websocket

  def start_link(_opts \\ []) do
    Logger.info("Starting link ")
    config = Application.get_env(:rujira, __MODULE__)
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    case Keyword.get(config, :websocket) do
      nil ->
        Supervisor.init([{@pool, config}], strategy: :one_for_one)

      _ ->
        Supervisor.init([{@pool, config}, {@socket, config}], strategy: :one_for_one)
    end
  end

  defdelegate subscribe(topic), to: @socket
  defdelegate query(query_fn, req), to: @pool
end
