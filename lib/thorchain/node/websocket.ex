defmodule Thorchain.Node.Websocket do
  use WebSockex
  require Logger

  @subscriptions ["tm.event='NewBlock'"]

  def start_link(config) do
    endpoint = config[:websocket]
    pubsub = Keyword.get(config, :pubsub)
    Logger.info("#{__MODULE__} Starting node websocket: #{endpoint}")

    case WebSockex.start_link("#{endpoint}/websocket", __MODULE__, %{pubsub: pubsub}) do
      {:ok, pid} ->
        for {s, idx} <- Enum.with_index(@subscriptions), do: subscribe(pid, idx, s)
        {:ok, pid}

      {:error, _} ->
        Logger.error("Error connecting to websocket #{endpoint}")
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
        Logger.debug("#{__MODULE__} Subscription #{id} event #{t}")
        pubsub = state[:pubsub]
        Phoenix.PubSub.broadcast(pubsub, t, v)

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
