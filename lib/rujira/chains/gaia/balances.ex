defmodule Rujira.Chains.Gaia.Balances do
  use GenServer

  def start_link(_) do
    Supervisor.start_link([__MODULE__.Listener], strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end
end
