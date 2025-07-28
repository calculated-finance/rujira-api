defmodule RujiraWeb.Resolvers.Index do
  @moduledoc """
  Handles GraphQL resolution for Index Protocol-related queries.
  """
  alias Absinthe.Relay
  alias Absinthe.Resolution.Helpers
  alias Rujira.Index

  def resolver(_, _, _) do
    Helpers.async(&Index.load_vaults/0)
  end

  def accounts(%{address: address}, _, _) do
    Helpers.async(fn -> Index.accounts(address) end)
  end

  def nav_bins(%{address: address}, %{from: from, to: to, resolution: resolution} = args, _) do
    Helpers.async(fn ->
      Index.query_nav_bins(address, from, to, resolution)
      |> Relay.Connection.from_query(&Rujira.Repo.all/1, args)
    end)
  end

  def type(module) do
    type =
      module
      |> to_string()
      |> String.split(".")
      |> List.last()
      |> String.downcase()

    {:ok, type}
  end

  def deposit_query(
        %{address: address, entry_adapter: entry_adapter},
        %{deposit_amount: deposit_amount, slippage_bps: slippage_bps},
        _
      ) do
    case entry_adapter do
      nil -> {:ok, nil}
      _ -> Index.deposit_query(address, deposit_amount, slippage_bps)
    end
  end
end
