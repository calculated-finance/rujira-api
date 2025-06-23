defmodule Thorchain.Tcy do
  @moduledoc """
  Module for handling Thorchain TCY related functionality.

  This module provides functionality for querying TCY claims and related data
  from the Thorchain network.
  """

  use Memoize

  @claims Path.join(:code.priv_dir(:rujira), "data/thorchain_tcy_claims.json")

  defmemo claim(asset, address) do
    case Enum.find(
           claims(),
           &(&1["asset"] == String.downcase(asset) and &1["address"] == address)
         ) do
      %{"tcy_claim" => amount} ->
        {:ok, amount}

      _ ->
        {:error, :not_found}
    end
  end

  defmemo claims() do
    @claims
    |> File.read!()
    |> Jason.decode!()
  end
end
