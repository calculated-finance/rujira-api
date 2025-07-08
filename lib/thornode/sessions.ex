defmodule Thornode.Sessions do
  @moduledoc """
  Manages Thornode processing sessions for live block streaming and backfilling.

  Each session tracks:
    - The starting block height (`start_height`)
    - The last processed block in live mode (`checkpoint_height`)
    - The backfilling range and progress (`restart_height`, `backfill_height`)
    - The current state of the session (`status`)

  Functions in this module handle the lifecycle:
    - Starting a new session when live streaming begins
    - Advancing the checkpoint as live blocks are processed
    - Marking sessions for backfill and tracking backfill progress
    - Completing sessions once backfilling is done
    - Querying for current or backfilling sessions
  """

  import Ecto.Query
  alias Rujira.Repo
  alias Thornode.Session

  @doc """
  Starts a new Thornode processing session.

  Sets both `start_height` and `checkpoint_height` to the provided `height`.
  Session status will be set to `:current`.
  """
  def start(height) do
    %Session{}
    |> Session.changeset(%{
      start_height: height,
      checkpoint_height: height,
      status: :current
    })
    |> Repo.insert()
  end

  @doc """
  Advances the `checkpoint_height` for the current session
  as live blocks are processed.
  """
  def update_checkpoint(height) do
    get_current_session()
    |> Session.changeset(%{checkpoint_height: height})
    |> Repo.update()
  end

  @doc """
  Updates the `backfill_height` for the backfill session
  as backfill blocks are processed.
  """
  def update_backfill_height(%Session{} = session, height) do
    session
    |> Session.changeset(%{backfill_height: height})
    |> Repo.update()
  end

  @doc """
  Marks the current session as requiring backfill, and records the
  chain tip (`restart_height`) at the time of restart.

  Should be called on restart/crash before starting a new session.

  If there is no current session, this is a no-op and returns :ok.
  """
  def start_backfill(restart_height) do
    case get_current_session() do
      nil ->
        :ok

      session ->
        session
        |> Session.changeset(%{
          status: :backfill,
          restart_height: restart_height
        })
        |> Repo.update()
    end
  end

  @doc """
  Marks a session as completed after all required blocks have been backfilled.

  Sets status to `:completed` and records the highest block successfully backfilled.
  """
  def complete_backfill(%Session{} = session, backfill_height) do
    session
    |> Session.changeset(%{
      status: :completed,
      backfill_height: backfill_height
    })
    |> Repo.update()
  end

  @doc """
  Fetches the most recent session with status `:current`.
  """
  def get_current_session do
    Repo.one(
      from s in Session,
        where: s.status == :current,
        order_by: [desc: s.inserted_at],
        limit: 1
    )
  end

  @doc """
  Fetches all sessions that are currently in `:backfill` status,
  ordered by oldest first.
  """
  def get_backfilling_sessions do
    Repo.all(
      from s in Session,
        where: s.status == :backfill,
        order_by: [asc: s.inserted_at]
    )
  end
end
