defmodule Thornode do
  @moduledoc """
  Main module for interacting with the Thornode.

  This module provides functionality for connecting to and querying the Thornode API,
  managing connection pools, and handling WebSocket connections for real-time updates.
  """
  use Supervisor
  require Logger

  @pool Thornode.Pool
  @socket Thornode.Websocket
  @backfill Thornode.Backfill

  def start_link(_opts \\ []) do
    Logger.info("Starting link ")
    config = Application.get_env(:rujira, __MODULE__)
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    case Keyword.get(config, :websocket) do
      nil ->
        Supervisor.init([{@pool, config}, @backfill], strategy: :one_for_one)

      _ ->
        Supervisor.init([{@pool, config}, {@socket, config}, @backfill], strategy: :one_for_one)
    end
  end

  defdelegate subscribe(topic), to: @socket
  defdelegate query(query_fn, req), to: @pool
end
