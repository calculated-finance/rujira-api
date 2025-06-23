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
end
