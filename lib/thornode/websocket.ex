defmodule Thornode.Websocket do
  use WebSockex
  require Logger

  @subscriptions ["tm.event='NewBlock'"]

  def start_link(config) do
    endpoint = config[:websocket]
    pubsub = Keyword.get(config, :pubsub)
    Logger.info("#{__MODULE__} Starting node websocket: #{endpoint}")

    case WebSockex.start_link("#{endpoint}/websocket", __MODULE__, %{pubsub: pubsub}) do
      {:ok, pid} ->
        for {s, idx} <- Enum.with_index(@subscriptions), do: do_subscribe(pid, idx, s)
        {:ok, pid}

      {:error, _} ->
        Logger.error("#{__MODULE__} Error connecting to websocket #{endpoint}")
        # Ignore for now
        :ignore
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
         {:ok, block} <-
           Thorchain.block(
             v
             |> Map.get(:block)
             |> Map.get(:header)
             |> Map.get(:height)
           ) do
      Logger.debug("#{__MODULE__} Subscription #{id} event #{t}")
      Phoenix.PubSub.broadcast(pubsub(), t, block)

      {:ok, state}
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

  defp pubsub() do
    Application.get_env(:rujira, :pubsub, Rujira.PubSub)
  end
end
