defmodule Thorchain.Swaps do
  alias Rujira.Repo
  alias Thorchain.Swaps.Swap

  use GenServer

  def start_link(_) do
    Supervisor.start_link([__MODULE__.Indexer], strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def insert_swap(params) do
    Swap.changeset(%Swap{}, params)
    |> Repo.insert()
  end
end
