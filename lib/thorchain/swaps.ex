defmodule Thorchain.Swaps do
  @moduledoc """
  Module for handling Thorchain swap operations.

  This module provides functionality for managing and querying base layer swaps
  """
  use GenServer

  def start_link(_) do
    Supervisor.start_link([__MODULE__.Listener], strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end
end
