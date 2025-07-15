defmodule Thornode.Backfill do
  @moduledoc """
  GenServer for backfilling missed blocks for all sessions needing backfill.
  Can be started as part of your application's supervision tree.
  """
  use GenServer
  require Logger
  alias Thornode.Session
  alias Thornode.Sessions

  @check_interval 300_000

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Triggers a backfill of all sessions currently in :backfill status.
  Can be called externally if needed.
  """
  def backfill_all do
    GenServer.cast(__MODULE__, :backfill_all)
  end

  def init(_init_arg) do
    send(self(), :backfill_all)
    {:ok, %{}}
  end

  def handle_info(:backfill_all, state) do
    do_backfill_all()
    {:noreply, state}
  end

  def handle_cast(:backfill_all, state) do
    do_backfill_all()
    {:noreply, state}
  end

  defp do_backfill_all do
    Sessions.get_backfilling_sessions()
    |> Enum.each(&backfill_session/1)

    Process.send_after(self(), :backfill_all, @check_interval)
  end

  defp backfill_session(%Session{checkpoint_height: from, restart_height: to} = session)
       when from < to do
    Logger.info("[Backfill] Session: backfilling blocks #{from + 1} to #{to}")

    case Enum.reduce_while(to..(from + 1), session, &backfill_height/2) do
      {:helt, height} ->
        Sessions.complete_backfill(session, height)

        Logger.info(
          "[Backfill] Session backfill partially completed from #{height} to #{from + 1}"
        )

      _ ->
        Sessions.complete_backfill(session, to)
        Logger.info("[Backfill] Session backfill completed back from #{to} to #{from + 1}")
    end

    :ok
  end

  defp backfill_session(%Session{checkpoint_height: from, restart_height: to}) do
    Logger.info("[Backfill] Nothing to backfill for this session (from == to)")
    :ok
  end

  defp backfill_height(height, session_acc) do
    case backfill_block(session_acc, height) do
      {:ok, session_acc} ->
        {:cont, session_acc}

      {:error, reason} ->
        Logger.error("[Backfill] Failed at block #{height}: #{inspect(reason)}")
        {:halt, height}
    end
  end

  defp backfill_block(session, height) do
    case Thorchain.block(height) do
      {:ok, block} ->
        Phoenix.PubSub.broadcast(pubsub(), "tendermint/event/NewBlock", block)
        Logger.info("[Backfill] Backfilled block #{height}")

        # Update backfill height this is used in case of crashing to resume backfilling from the last height
        Sessions.update_backfill_height(session, height)
        {:ok, session}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp pubsub, do: Application.get_env(:rujira, :pubsub, Rujira.PubSub)
end
