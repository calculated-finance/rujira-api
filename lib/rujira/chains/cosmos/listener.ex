defmodule Rujira.Chains.Cosmos.Listener do
  defmacro __using__(opts) do
    chain = Keyword.fetch!(opts, :chain)
    ws = Keyword.fetch!(opts, :ws)

    quote do
      use WebSockex
      require Logger

      @chain unquote(chain)
      @ws unquote(ws)
      @subscription "tm.event='NewBlock'"

      def start_link(_) do
        case WebSockex.start_link("#{@ws}/websocket", __MODULE__, %{}) do
          {:ok, pid} ->
            subscribe(pid, 0, @subscription)
            {:ok, pid}

          {:error, err} ->
            {:error, err}
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
        with {:ok, %{id: id, result: %{data: %{type: "tendermint/event/NewBlock", value: v}}}} <-
               Jason.decode(msg, keys: :atoms),
             :ok <- process_block(v) do
          {:ok, state}
        else
          {:ok, %{id: id, jsonrpc: "2.0", result: %{}}} ->
            Logger.info("#{__MODULE__} Subscription #{id} successful")
            {:ok, state}

          err ->
            err
        end
      end

      def handle_cast({:send, {_type, msg} = frame}, state) do
        Logger.debug("#{__MODULE__} [send] #{msg}")
        {:reply, frame, state}
      end

      def process_block(%{result_finalize_block: finalize}) do
        finalize
        |> Map.get(:tx_results, [])
        |> Enum.flat_map(& &1.events)
        |> Enum.concat(Map.get(finalize, :events, []))
        |> process_events()
      end

      def process_block(_), do: {:error, :invalid_block}

      def process_events(events) do
        events
        |> Enum.flat_map(&scan_event/1)
        |> Enum.uniq()
        |> Enum.each(fn address ->
          Logger.debug("#{__MODULE__} change #{address}")
          Rujira.Events.publish_node(:layer_1_account, "#{@chain}:#{address}")
        end)

        :ok
      end

      defp scan_event(%{attributes: attributes, type: "transfer"}),
        do: extract_addresses(attributes)

      defp scan_event(_), do: []

      defp extract_addresses(attrs) do
        Enum.reduce(attrs, [], fn
          %{key: "recipient", value: r}, acc -> [r | acc]
          %{key: "sender", value: s}, acc -> [s | acc]
          _, acc -> acc
        end)
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
  end
end
