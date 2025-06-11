defmodule Thornode.Observer do
  @moduledoc """
  A behaviour module for creating blockchain observers that automatically
  subscribe to NewBlock events and provide AppSignal tracing.

  ## Usage

      defmodule Rujira.BlockObserver do
        use Thornode.Observer

        def handle_new_block(%{txs: txs}, state) do
          # Process transactions
          scan_txs(txs)
          {:noreply, state}
        end

        defp scan_txs(txs) do
          # Your transaction scanning logic
        end
      end

  The `handle_new_block/2` callback will be automatically wrapped with
  AppSignal tracing.
  """

  defmacro __using__(_opts) do
    quote do
      use GenServer
      require Logger

      @behaviour Thornode.Observer

      def start_link(init_arg \\ []) do
        GenServer.start_link(__MODULE__, init_arg)
      end

      @impl true
      def init(state) do
        Phoenix.PubSub.subscribe(Rujira.PubSub, "tendermint/event/NewBlock")
        {:ok, state}
      end

      @impl true
      def handle_info(
            %{header: %{chain_id: chain_id, height: height, time: time}} = message,
            state
          ) do
        action_name = String.trim_leading("#{__MODULE__}#handle_new_block", "Elixir.")

        "observer"
        |> Appsignal.Tracer.create_span()
        |> Appsignal.Span.set_name(action_name)
        |> Appsignal.Span.set_sample_data(
          "params",
          %{
            chain_id: chain_id,
            height: height,
            time: DateTime.to_iso8601(time)
          }
        )

        Appsignal.instrument("handle_new_block", fn ->
          handle_new_block(message, state)
        end)
      end

      # Allow other handle_info patterns to be defined by the implementing module
      def handle_info(message, state) do
        Logger.warning("Unhandled message in #{__MODULE__}: #{inspect(message)}")
        {:noreply, state}
      end

      # Make handle_info overridable so implementing modules can add their own patterns
      defoverridable handle_info: 2
    end
  end

  @doc """
  Callback for handling new block events.

  This callback is invoked when a new block event is received from the PubSub.
  The message will contain transaction data in the `txs` field.

  ## Parameters

    * `message` - The new block message containing transaction data
    * `state` - The current GenServer state

  ## Returns

  Should return a standard GenServer handle_info response:
    * `{:noreply, new_state}`
    * `{:noreply, new_state, timeout | :hibernate}`
    * `{:stop, reason, new_state}`
  """
  @callback handle_new_block(message :: map(), state :: term()) ::
              {:noreply, new_state :: term()}
              | {:noreply, new_state :: term(), timeout() | :hibernate}
              | {:stop, reason :: term(), new_state :: term()}
end
