defmodule Thornode.Websocket do
  @moduledoc """
  WebSocket client for connecting to ThorNode's WebSocket endpoint.

  Integrates with Thornode.Sessions to track block-processing sessions.
  Uses 'broadcast first, then checkpoint' for at-least-once delivery semantics.
  """
  use WebSockex
  require Logger

  alias Thornode.Sessions

  @subscriptions ["tm.event='NewBlock'"]

  def start_link(config) do
    endpoint = config[:websocket]
    pubsub = Keyword.get(config, :pubsub)
    Logger.info("#{__MODULE__} Starting node websocket: #{endpoint}")

    case WebSockex.start_link("#{endpoint}/websocket", __MODULE__, %{
           pubsub: pubsub,
           session_started: false
         }) do
      {:ok, pid} ->
        for {s, idx} <- Enum.with_index(@subscriptions), do: do_subscribe(pid, idx, s)
        {:ok, pid}

      {:error, reason} ->
        Logger.error("#{__MODULE__} Error connecting to websocket #{endpoint}")
        {:error, reason}
    end
  end

  def handle_connect(_conn, state) do
    Logger.info("#{__MODULE__} Connected")
    {:ok, state}
  end

  def handle_disconnect(%{conn: %{host: host}}, state) do
    Logger.error("#{__MODULE__} disconnected: #{host}")
    {:ok, state}
  end

  @spec subscribe(binary()) :: :ok | {:error, {:already_registered, pid()}}
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(pubsub(), topic)
  end

  def handle_frame({:text, msg}, state) do
    with {:ok, %{id: id, result: %{data: %{type: t, value: v}}}} <-
           Jason.decode(msg, keys: :atoms),
         height <- get_height(v),
         {:ok, block} <- Thorchain.block(height) do
      Logger.debug("#{__MODULE__} Subscription #{id} event #{t}")

      # Move previous :current session into :backfill with the new starting height
      backfill(height, state)

      # Always broadcast the block first
      # This ensures that the block is processed by any subscribers before the checkpoint is updated
      Phoenix.PubSub.broadcast(pubsub(), t, block)

      # Now start or update session
      update_session(height, state)
    else
      {:ok, %{id: id, jsonrpc: "2.0", result: %{}}} ->
        Logger.info("#{__MODULE__} Subscription #{id} successful")
        {:ok, state}

      {:error, %{message: message}} ->
        Logger.error("#{__MODULE__} #{message}")
        {:close, state}

      {:error, error} ->
        Logger.error("#{__MODULE__} #{inspect(error)}")
        {:close, state}
    end
  end

  def handle_cast({:send, {_type, msg} = frame}, state) do
    Logger.debug("#{__MODULE__} [send] #{msg}")

    {:reply, frame, state}
  end

  defp do_subscribe(pid, id, query) do
    message =
      Jason.encode!(%{
        jsonrpc: "2.0",
        method: "subscribe",
        id: id,
        params: %{
          query: query
        }
      })

    WebSockex.send_frame(pid, {:text, message})
  end

  defp pubsub, do: Application.get_env(:rujira, :pubsub, Rujira.PubSub)

  defp get_height(v) do
    v
    |> Map.get(:block)
    |> Map.get(:header)
    |> Map.get(:height)
  end

  defp backfill(height, %{session_started: false}), do: Sessions.start_backfill(height)
  defp backfill(_, %{session_started: true}), do: :ok

  defp update_session(height, %{session_started: false} = state) do
    case Sessions.start(height) do
      {:ok, _session} ->
        Logger.info("#{__MODULE__} Started new session at block #{height}")
        {:ok, %{state | session_started: true}}

      {:error, changeset} ->
        Logger.error("#{__MODULE__} Failed to start session: #{inspect(changeset)}")
        {:ok, state}
    end
  end

  defp update_session(height, %{session_started: true} = state) do
    case Sessions.update_checkpoint(height) do
      {:ok, _session} ->
        {:ok, state}

      {:error, changeset} ->
        Logger.error("#{__MODULE__} Failed to update session checkpoint: #{inspect(changeset)}")

        {:ok, state}
    end
  end
end
