defmodule Rujira.Chains.Gaia.Websocket do
  use WebSockex
  require Logger

  def start_link(_opts \\ []) do
    config = Application.get_env(:rujira, __MODULE__)
    pubsub = Application.get_env(:rujira, :pubsub, Rujira.PubSub)
    Logger.info("#{__MODULE__} Starting gaia websocket: #{config[:websocket]}")

    case WebSockex.start_link("#{config[:websocket]}/websocket", __MODULE__, %{pubsub: pubsub}) do
      {:ok, pid} ->
        for {s, idx} <- Enum.with_index(config[:subscriptions]), do: subscribe(pid, idx, s)
        {:ok, pid}

      {:error, _} ->
        Logger.error("Error connecting to websocket #{config[:websocket]}")
        # Ignore for now
        :ignore
    end
  end

  def handle_connect(_conn, state) do
    Logger.info("#{__MODULE__} Connected")
    {:ok, state}
  end

  def handle_disconnect(_status, _state) do
    raise "#{__MODULE__} Disconnected"
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg, keys: :atoms) do
      {:ok, %{id: id, result: %{data: %{type: t, value: v}}}} ->
        Logger.debug("#{__MODULE__} Subscription #{id} event gaia/#{t}")
        pubsub = state[:pubsub]
        Phoenix.PubSub.broadcast(pubsub, "gaia/#{t}", v)
        {:ok, state}

      {:ok, %{id: id, jsonrpc: "2.0", result: %{}}} ->
        Logger.info("#{__MODULE__} Subscription #{id} successful")
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  def handle_cast({:send, {_type, msg} = frame}, state) do
    Logger.debug("#{__MODULE__} [send] #{msg}")

    {:reply, frame, state}
  end

  defp subscribe(pid, id, query) do
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
end
