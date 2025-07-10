defmodule Thornode.WebsocketManager do
  @moduledoc """
  Manages a single Thornode.Websocket connection with automatic failover.

  Starts the WebSocket client, monitors it, and fails over to the next endpoint
  on disconnect or error. Exposes API for subscription and messaging.
  """

  use GenServer
  require Logger

  ## --- Public API ---

  def start_link(config) do
    Logger.info("Starting Thornode.WebsocketManager link")
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @doc """
  Subscribe to a topic via the current live WebSocket.
  """
  def subscribe(topic), do: GenServer.call(__MODULE__, {:subscribe, topic})

  ## --- GenServer Implementation ---

  def init(opts) do
    endpoints = Keyword.get(opts, :websockets)
    state = %{endpoints: endpoints, current: 0, ws_pid: nil, ws_mon: nil}
    {:ok, state, {:continue, :connect}}
  end

  # Start first connection on continue
  def handle_continue(:connect, state) do
    {:noreply, connect_to_ws(state)}
  end

  # Forward subscribe to the child
  def handle_call({:subscribe, topic}, _from, %{ws_pid: ws_pid} = state) when is_pid(ws_pid) do
    Thornode.Websocket.subscribe(topic)
    {:reply, :ok, state}
  end

  def handle_call({:subscribe, _topic}, _from, state) do
    {:reply, {:error, :not_connected}, state}
  end

  # Trap DOWNs from WebSocket
  def handle_info({:DOWN, ref, :process, pid, reason}, %{ws_mon: ref, ws_pid: pid} = state) do
    Logger.error("[WebsocketManager] Connection lost (#{inspect(reason)}), failing over…")
    state = %{state | ws_pid: nil, ws_mon: nil, current: next_index(state)}
    # Delay before reconnect to avoid hot loop if all endpoints are down
    Process.send_after(self(), :reconnect, 2_000)
    {:noreply, state}
  end

  def handle_info(:reconnect, state) do
    {:noreply, connect_to_ws(state)}
  end

  ## --- Helper Functions ---

  # Connect to the next available endpoint
  defp connect_to_ws(%{endpoints: eps, current: idx} = state) do
    url = Enum.at(eps, idx)
    Logger.info("[WebsocketManager] Connecting to WebSocket at #{url}…")

    case Thornode.Websocket.start_link(websocket: url) do
      {:ok, pid} ->
        Logger.info("[WebsocketManager] Connected to #{url}")
        mon = Process.monitor(pid)
        %{state | ws_pid: pid, ws_mon: mon}

      {:error, _reason} ->
        Logger.error("[WebsocketManager] Failed to connect to #{url}, will try next.")
        # Move to next and schedule reconnect
        state = %{state | ws_pid: nil, ws_mon: nil, current: next_index(state)}
        Process.send_after(self(), :reconnect, 2_000)
        state
    end
  end

  # Get next index in the list of endpoints
  # use the rem function to wrap around the list
  defp next_index(%{endpoints: eps, current: idx}) do
    rem(idx + 1, length(eps))
  end
end
