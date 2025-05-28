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
    with [league, season, account] <- String.split(id, "/"),
         {:ok, %{} = account} <- load_account(league, season, account) do
      {:ok, Map.put(account, :id, id)}
    else
      {:ok, nil} -> {:error, :not_found}
      _ -> {:error, :invalid_id}
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

  def leaderboard(league, season) do
    TxEvent
    |> join(:inner, [tx], e in assoc(tx, :events))
    |> join(:left, [tx, e], l in subquery(leaders(league, season)), on: l.address == tx.address)
    |> where([tx, e], e.league == ^league and e.season == ^season)
    |> group_by([tx], tx.address)
    |> select([tx, e, l], %{
      address: tx.address,
      points: fragment("CAST(COALESCE(?, 0) AS bigint)", sum(e.points)),
      rank: dense_rank() |> over(partition_by: tx.address, order_by: sum(e.points)),
      total_tx: count(tx),
      badges:
        fragment("ARRAY_AGG(DISTINCT(?)) FILTER (WHERE ? IS NOT NULL)", l.category, l.category)
    })
  end

  def leaders(league, season) do
    Event
    |> where([le], le.league == ^league and le.season == ^season)
    |> join(:inner, [le], lte in TxEvent, on: le.tx_event_id == lte.id)
    |> group_by([le, lte], [lte.address, lte.category])
    |> select([le, lte], %{
      address: lte.address,
      category: lte.category,
      category_points: sum(le.points),
      rank:
        over(
          rank(),
          partition_by: lte.category,
          order_by: [desc: sum(le.points)]
        )
    })
    |> subquery()
    |> where([cl], cl.rank == 1)
  end
end
