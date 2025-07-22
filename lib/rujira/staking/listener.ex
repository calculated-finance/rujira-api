defmodule Rujira.Staking.Listener do
  @moduledoc """
  Listens for and processes staking-related blockchain events.

  Handles block transactions to detect staking events, updates cached data,
  and publishes real-time updates through the events system.
  """
  alias Rujira.Staking
  use Supervisor

  def start_link(_) do
    with {:ok, pairs} <- Staking.list_pools() do
      Supervisor.start_link(
        Enum.map(pairs, &Supervisor.child_spec({__MODULE__.Pool, &1}, id: &1.id)),
        strategy: :one_for_one
      )
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end
end
