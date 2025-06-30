defmodule Rujira.Bank do
  @moduledoc """
  Manages token supply and transfer operations.
  """
  use Supervisor
  alias __MODULE__.Supply

  def start_link(_) do
    children = [{Supply, %{}}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def total_supply do
    {:ok, GenServer.call(Supply, :get)}
  end

  def supply(denom) do
    case Map.get(GenServer.call(Supply, :get), denom) do
      nil -> {:error, :not_found}
      supply -> {:ok, supply}
    end
  end
end
