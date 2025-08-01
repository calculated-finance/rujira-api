defmodule Rujira.Perps.Listener do
  @moduledoc """
  Starts listeners for Perps Protocol events.

  It implements a discrete observer for each individual event type.
  """
  use Supervisor

  def start_link(_) do
    with {:ok, pools} <- pool_children() do
      Supervisor.start_link(pools, strategy: :one_for_one)
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  # Creates Perps pool listeners for perps pools
  defp pool_children do
    with {:ok, pools} <- Rujira.Perps.list_pools() do
      {:ok,
       pools
       |> Enum.map(&Supervisor.child_spec({__MODULE__.Pool, &1}, id: "Pool" <> &1.id))}
    end
  end
end
