defmodule Rujira.Leagues do
  use GenServer
  alias Rujira.Repo
  alias Rujira.Leagues.TxEvent
  alias Rujira.Leagues.Event
  import Ecto.Query

  @multiplier 69

  def multiplier(), do: @multiplier

  def start_link(_) do
    children = [__MODULE__.Collectors]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def init(state), do: {:ok, state}

  # For now, only genesis is loaded, later linked to the smart contracts
  def load_leagues() do
    {:ok, [%{league: "genesis", season: 0}]}
  end

  def account_from_id(id) do
    [league, season, account] = String.split(id, "/")

    with {:ok, account} <- load_account(league, season, account) do
      {:ok, Map.put(account, :id, id)}
    end
  end

  def insert_tx_events(events) do
    now = DateTime.utc_now()

    {_, rows} =
      events
      |> Enum.map(&Map.merge(&1, %{inserted_at: now, updated_at: now}))
      |> then(fn entries ->
        Repo.insert_all(TxEvent, entries,
          returning: [:id, :address, :revenue, :category],
          on_conflict: :nothing
        )
      end)

    rows
  end

  def update_leagues(tx_events) do
    Enum.each(tx_events, fn tx_event ->
      %Event{
        league: "genesis",
        season: 0,
        points: tx_event.revenue * @multiplier,
        tx_event_id: tx_event.id
      }
      |> Repo.insert()
    end)
  end

  def stats(league, season) do
    Event
    |> join(:inner, [le], tx in assoc(le, :tx_event))
    |> where([le, tx], le.league == ^league and le.season == ^season)
    |> select([le, tx], %{
      total_points: fragment("CAST(COALESCE(?, 0) AS bigint)", sum(le.points)),
      participants: count(fragment("DISTINCT ?", tx.address))
    })
    |> Repo.one()
    |> then(&{:ok, &1})
  end

  def load_account(league, season, account) do
    Event
    |> join(:inner, [le], tx in assoc(le, :tx_event))
    |> where([le, tx], le.league == ^league and le.season == ^season and tx.address == ^account)
    |> group_by([le, tx], [le.league, le.season, tx.address])
    |> select([le, tx], %{
      league: le.league,
      season: le.season,
      address: tx.address,
      points: fragment("CAST(COALESCE(?, 0) AS bigint)", sum(le.points)),
      total_tx: fragment("COUNT(DISTINCT ?)", tx.txhash)
    })
    |> Repo.one()
    |> then(&{:ok, &1})
  end

  def account_txs(address, league, season) do
    Event
    |> join(:inner, [le], tx in assoc(le, :tx_event))
    |> where([le, tx], le.league == ^league and le.season == ^season and tx.address == ^address)
    |> group_by([_le, tx], [tx.txhash, tx.category])
    |> select([le, tx], %{
      tx_hash: tx.txhash,
      timestamp: min(tx.timestamp),
      height: min(tx.height),
      points: sum(le.points),
      category: tx.category
    })
    |> subquery()
    |> order_by(desc: :timestamp)
  end

  def leaderboard_at_time(league, season, time) do
    Event
    |> join(:inner, [le], tx in assoc(le, :tx_event))
    |> where([le, tx], le.league == ^league and le.season == ^season and tx.timestamp <= ^time)
    |> group_by([le, tx], tx.address)
    |> select([le, tx], %{
      address: tx.address,
      points: fragment("CAST(COALESCE(?, 0) AS bigint)", sum(le.points)),
      total_tx: fragment("COUNT(DISTINCT ?)", tx.txhash)
    })
    |> subquery()
    |> select([r], %{
      address: r.address,
      points: r.points,
      total_tx: r.total_tx,
      rank: fragment("DENSE_RANK() OVER (ORDER BY ? DESC)", r.points)
    })
    |> subquery()
    |> order_by(desc: :rank)
  end

  def leaderboard(league, season) do
    now = DateTime.utc_now()
    week_ago = Rujira.Resolution.shift_from_back(now, 7, "1D") |> Rujira.Resolution.truncate("1D")

    current = leaderboard_at_time(league, season, now) |> subquery()
    previous = leaderboard_at_time(league, season, week_ago) |> subquery()

    current
    |> join(:left, [curr], past in ^previous, on: past.address == curr.address)
    |> select([curr, past], %{
      address: curr.address,
      points: curr.points,
      total_tx: curr.total_tx,
      rank: curr.rank,
      rank_change:
        fragment("CASE WHEN ? IS NULL THEN NULL ELSE ? - ? END", past.rank, past.rank, curr.rank)
    })
  end

  def badges(league, season) do
    base =
      Event
      |> join(:inner, [le], tx in assoc(le, :tx_event))
      |> where([le, tx], le.league == ^league and le.season == ^season)
      |> group_by([le, tx], [tx.category, tx.address])
      |> select([le, tx], %{
        category: tx.category,
        address: tx.address,
        total_points: sum(le.points)
      })

    max_per_category =
      base
      |> subquery()
      |> group_by([p], p.category)
      |> select([p], %{
        category: p.category,
        max_points: max(p.total_points)
      })

    base
    |> subquery()
    |> join(:inner, [p], maxp in subquery(max_per_category),
      on: p.category == maxp.category and p.total_points == maxp.max_points
    )
    |> select([p, _maxp], %{
      category: p.category,
      address: p.address,
      points: p.total_points
    })
    |> Repo.all()
    |> Enum.group_by(& &1.address)
    |> Enum.map(fn {address, items} ->
      %{
        address: address,
        badges: Enum.map(items, fn %{category: category} -> category end)
      }
    end)
    |> then(&{:ok, &1})
  end
end
