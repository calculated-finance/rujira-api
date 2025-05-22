defmodule RujiraWeb.Resolvers.Leagues do
  @moduledoc """
  Resolver for Ruji Leagues endpoints
  """
  alias Absinthe.Resolution.Helpers
  alias Rujira.Leagues
  alias Rujira.Repo
  alias Absinthe.Relay

  def resolver(_, _, _) do
    Helpers.async(&Leagues.load_leagues/0)
  end

  def leaderboard(%{league: league, season: season}, args, _) do
    Helpers.async(fn ->
      Leagues.leaderboard(league, season, args.search, args.sort_by, args.sort_dir)
      |> Relay.Connection.from_query(&Repo.all/1, args)
    end)
  end

  def badges(%{league: league, season: season}, _, _) do
    Helpers.async(fn ->
      with {:ok, badges} <- Leagues.badges(league, season) do
        {:ok, badges}
      end
    end)
  end

  def stats(%{league: league, season: season}, _, _) do
    Helpers.async(fn ->
      with {:ok, stats} <- Leagues.stats(league, season) do
        {:ok, stats}
      end
    end)
  end

  def account_txs(%{address: address, league: league, season: season}, args, _) do
    Helpers.async(fn ->
      Leagues.account_txs(address, league, season)
      |> Relay.Connection.from_query(&Repo.all/1, args)
    end)
  end
end
