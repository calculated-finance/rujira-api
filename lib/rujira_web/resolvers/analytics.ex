defmodule RujiraWeb.Resolvers.Analytics do
  @moduledoc """
  Handles GraphQL resolution for analytics-related queries.
  """
  alias Absinthe.Relay
  alias Absinthe.Resolution.Helpers
  alias Rujira.Analytics.Swap
  alias Rujira.Repo

  def swap_bins(_, %{from: f, to: t, resolution: r, period: p} = args, _) do
    with from <- Rujira.Resolution.truncate(f, r) do
      Helpers.async(fn ->
        Swap.bins(from, t, r, p)
        |> Relay.Connection.from_query(&Repo.all/1, args)
      end)
    end
  end

  def swap_volume_by_asset(_, %{from: f, to: t}, _) do
    Helpers.async(fn -> Swap.volume_by_asset(f, t) end)
  end

  def swap_volume_by_chain(_, %{from: f, to: t}, _) do
    Helpers.async(fn -> Swap.volume_by_chain(f, t) end)
  end
end
