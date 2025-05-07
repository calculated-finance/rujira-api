defmodule Rujira.Leagues.Collectors do
  @moduledoc false
  use GenServer

  def start_link(_) do
    children = [
      __MODULE__.Contract,
      __MODULE__.Swap
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state), do: {:ok, state}
end
