defmodule RujiraWeb.Resolvers.Analytics do
  alias Absinthe.Resolution.Helpers
  alias Absinthe.Relay
  alias Rujira.Repo

  def swap_snapshots(_, %{from: f, to: t, resolution: r, period: p} = args, _) do
    with from <- Rujira.Resolution.truncate(f, r) do
      Helpers.async(fn ->
        Rujira.Analytics.SwapQueries.snapshots(from, t, r, p)
        |> Relay.Connection.from_query(&Repo.all/1, args)
      end)
    end
  end
end
