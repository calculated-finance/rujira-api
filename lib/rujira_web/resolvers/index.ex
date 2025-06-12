defmodule RujiraWeb.Resolvers.Index do
  alias Absinthe.Resolution.Helpers
  alias Rujira.Index
  alias Absinthe.Relay

  def resolver(_, _, _) do
    Helpers.async(&Index.load_vaults/0)
  end

  def accounts(%{address: address}, _, _) do
    Helpers.async(fn ->
      with {:ok, pools} <- Index.load_vaults() do
        Rujira.Enum.reduce_while_ok(pools, [], fn x ->
          case Index.load_account(x, address) do
            {:ok, %{shares: 0}} -> :skip
            other -> other
          end
        end)
      end
    end)
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
