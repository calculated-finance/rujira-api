defmodule Rujira.Fin.Listener do
  @moduledoc """
  Starts listeners for Fin events.
  """
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(
      [
        __MODULE__.Bow,
        __MODULE__.Order,
        __MODULE__.Pair,
        __MODULE__.Thorchain
      ],
      strategy: :one_for_one
    )
  end

  @impl true
  def init(state) do
    {:ok, state}
  end
end
