defmodule Rujira.Fin.Listener do
  @moduledoc """
  Starts listeners for Fin Protocol events.

  It implements a discrete observer for each individual event type.
  """
  use Supervisor

  def start_link(_) do
    with {:ok, pairs} <- pair_children(),
         {:ok, orders} <- order_children(),
         {:ok, bows} <- bow_children(),
         {:ok, thorchains} <- thorchain_children() do
      [pairs, orders, bows, thorchains]
      |> Enum.concat()
      |> Supervisor.start_link(strategy: :one_for_one)
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  # Creates Thorchain oracle listeners for pairs with oracle configuration
  defp thorchain_children do
    with {:ok, pairs} <- Rujira.Fin.list_pairs() do
      {:ok,
       pairs
       |> Enum.filter(&(not is_nil(&1.oracle_base) and not is_nil(&1.oracle_quote)))
       |> Enum.map(&Supervisor.child_spec({__MODULE__.Thorchain, &1}, id: "Thorchain" <> &1.id))}
    end
  end

  # Creates trade listeners to update order books when trades occur
  defp pair_children do
    with {:ok, pairs} <- Rujira.Fin.list_pairs() do
      {:ok, Enum.map(pairs, &Supervisor.child_spec({__MODULE__.Pair, &1}, id: "Pair" <> &1.id))}
    end
  end

  # Creates order event listeners to track order placements/cancellations
  defp order_children do
    with {:ok, pairs} <- Rujira.Fin.list_pairs() do
      {:ok, Enum.map(pairs, &Supervisor.child_spec({__MODULE__.Order, &1}, id: "Order" <> &1.id))}
    end
  end

  # Creates Bow market maker listeners to update books for MM actions
  defp bow_children do
    with {:ok, pools} <- Rujira.Bow.list_pools() do
      {:ok, Enum.map(pools, &Supervisor.child_spec({__MODULE__.Bow, &1}, id: "Bow" <> &1.id))}
    end
  end
end
