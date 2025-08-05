defmodule Rujira.Analytics do
  @moduledoc """
  Starts analytics listeners.
  """
  use GenServer
  alias Rujira.Analytics.Staking
  alias Rujira.Analytics.Swap

  def start_link(_) do
    children = [
      Swap.Indexer,
      Staking
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end
end
