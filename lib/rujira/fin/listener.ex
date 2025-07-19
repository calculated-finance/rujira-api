defmodule Rujira.Fin.Listener do
  @moduledoc """
  Starts listeners for Fin Protocol events.

  It implements a discrete observer for each individual event type.
  """
  use Supervisor

  def start_link(_) do
    # Start individual listeners for each pair/event type
    pair_children()
    |> Enum.concat(thorchain_children())
    |> Enum.concat(order_children())
    |> Enum.concat(bow_children())
    |> Supervisor.start_link(strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  # Creates Thorchain oracle listeners for pairs with oracle configuration
  defp thorchain_children do
    with {:ok, pairs} <- Rujira.Fin.list_pairs() do
      pairs
      |> Enum.filter(&(not is_nil(&1.oracle_base) and not is_nil(&1.oracle_quote)))
      |> Enum.map(&Supervisor.child_spec({__MODULE__.Thorchain, &1}, id: &1.id))
    end
  end

  # Creates trade listeners to update order books when trades occur
  defp pair_children do
    with {:ok, pairs} <- Rujira.Fin.list_pairs() do
      pairs
      |> Enum.map(&Supervisor.child_spec({__MODULE__.Pair, &1}, id: &1.id))
    end
  end

  # Creates order event listeners to track order placements/cancellations
  defp order_children do
    with {:ok, pairs} <- Rujira.Fin.list_pairs() do
      pairs
      |> Enum.map(&Supervisor.child_spec({__MODULE__.Order, &1}, id: &1.id))
    end
  end

  # Creates Bow market maker listeners to update books for MM actions
  defp bow_children do
    with {:ok, pools} <- Rujira.Bow.list_pools() do
      pools
      |> Enum.map(&Supervisor.child_spec({__MODULE__.Bow, &1}, id: &1.id))
    end
  end
end
