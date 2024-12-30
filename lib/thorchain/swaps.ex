defmodule Thorchain.Swaps do
  alias Rujira.Repo
  alias Thorchain.Swaps.Swap

  def insert_swap(params) do
    Swap.changeset(%Swap{}, params)
    |> Repo.insert()
  end
end
