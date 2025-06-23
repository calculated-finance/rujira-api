defmodule RujiraWeb.Resolvers.Analytics do
  @moduledoc """
  Handles GraphQL resolution for analytics-related queries.
  """
  alias Absinthe.Relay
  alias Absinthe.Resolution.Helpers
  alias Rujira.Analytics.SwapQueries
  alias Rujira.Repo
  alias Rujira.Resolution

  def swap_snapshots(_, %{from: f, to: t, resolution: r, period: p} = args, _) do
    with from <- Resolution.truncate(f, r) do
      Helpers.async(fn ->
        SwapQueries.snapshots(from, t, r, p)
        |> Relay.Connection.from_query(&Repo.all/1, args)
      end)
    end
  end
end
