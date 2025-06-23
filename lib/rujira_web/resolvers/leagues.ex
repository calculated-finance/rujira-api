defmodule RujiraWeb.Resolvers.Leagues do
  @moduledoc """
  Handles GraphQL resolution for Leagues-related queries.
  """
  alias Absinthe.Relay
  alias Absinthe.Resolution.Helpers
  alias Rujira.Leagues
  alias Rujira.Repo

  def resolver(_, _, _) do
    Helpers.async(&Leagues.load_leagues/0)
  end

  def leaderboard(%{league: league, season: season}, args, _) do
    Helpers.async(fn ->
      league
      |> Leagues.leaderboard(season, Map.get(args, :search), args.sort_by, args.sort_dir)
      |> Relay.Connection.from_query(&Repo.all/1, args)
    end)
  end

  def stats(%{league: league, season: season}, _, _) do
    Helpers.async(fn ->
      Leagues.stats(league, season)
    end)
  end

  def account_txs(%{address: address, league: league, season: season}, args, _) do
    Helpers.async(fn ->
      address
      |> Leagues.account_txs(league, season)
      |> Relay.Connection.from_query(&Repo.all/1, args)
    end)
  end
end
