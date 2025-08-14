defmodule Thorchain.Tor do
  @moduledoc """
  Module for handling Thorchain TOR (Thorchain Oracle Reports) functionality.

  This module provides functionality for managing TOR candles and related data
  in the Thorchain network, including data indexing and querying.
  """
  alias Rujira.Repo
  alias Thorchain.Tor.Candle
  import Ecto.Query
  require Logger
  use Supervisor

  def start_link(_) do
    children =
      Rujira.Resolution.resolutions()
      |> Enum.map(&Supervisor.child_spec({Candle, &1}, id: &1))

    Supervisor.start_link([__MODULE__.Indexer | children], strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @spec candle_from_id(any()) :: {:error, :not_found} | {:ok, Candle.t()}
  def candle_from_id(id) do
    [asset, resolution, bin] = String.split(id, "/")

    case get_candle(asset, resolution, bin) do
      nil -> {:error, :not_found}
      candle -> {:ok, candle}
    end
  end

  @spec get_candle(String.t(), String.t(), String.t()) :: Candle.t() | nil
  def get_candle(asset, resolution, bin) do
    Candle
    |> where(asset: ^asset, resolution: ^resolution, bin: ^bin)
    |> Repo.one()
  end

  def range_candles(asset, from, to, resolution) do
    Candle
    |> where(
      asset: ^asset,
      resolution: ^resolution
    )
    |> where([c], c.bin >= ^from)
    |> where([c], c.bin <= ^to)
    |> order_by(asc: :bin)
    |> Repo.all()
  end

  def insert_candles(time, resolution) do
    now = DateTime.utc_now()

    bin =
      from(c in Candle,
        where: c.resolution == ^resolution and c.asset == "BTC.BTC",
        order_by: [desc: c.bin],
        limit: 1,
        select: c.bin
      )
      |> Repo.one()

    new =
      from(c in Candle, where: c.bin == ^bin)
      |> Repo.all()
      |> Enum.map(
        &%{
          id: Candle.id(&1.asset, &1.resolution, time),
          asset: &1.asset,
          resolution: &1.resolution,
          high: &1.close,
          low: &1.close,
          open: &1.close,
          close: &1.close,
          bin: time,
          inserted_at: now,
          updated_at: now
        }
      )

    Repo.insert_all(Candle, new,
      # Conflict will be hit if race condition has triggered insert before this is reached
      on_conflict: :nothing,
      returning: true
    )
    |> broadcast_candles()
  end

  def update_candles(prices) do
    entries =
      Enum.flat_map(prices, fn {asset, price, timestamp} ->
        Rujira.Resolution.active(timestamp)
        |> Enum.map(&to_candle(asset, price, &1))
      end)

    Repo.insert_all(
      Candle,
      entries,
      on_conflict: candle_conflict(),
      conflict_target: [:asset, :resolution, :bin],
      returning: true
    )
    |> broadcast_candles()

    # publish the Thorchain pool for each asset after the candles are inserted
    for {asset, _price, _timestamp} <- prices do
      Rujira.Events.publish_node(:thorchain_pool, asset)
    end
  end

  defp to_candle(asset, price, {resolution, bin}) do
    now = DateTime.utc_now()

    %{
      id: Candle.id(asset, resolution, bin),
      asset: asset,
      resolution: resolution,
      bin: bin,
      high: price,
      low: price,
      open: price,
      close: price,
      inserted_at: now,
      updated_at: now
    }
  end

  defp candle_conflict do
    from(c in Candle,
      update: [
        set: [
          high: fragment("GREATEST(EXCLUDED.high, ?)", c.high),
          low: fragment("LEAST(EXCLUDED.low, ?)", c.low),
          open: fragment("COALESCE(?, EXCLUDED.open)", c.open),
          close: fragment("EXCLUDED.close"),
          updated_at: fragment("EXCLUDED.updated_at")
        ]
      ]
    )
  end

  defp broadcast_candles({_count, candles}) do
    for c <- candles do
      Logger.debug("#{__MODULE__} broadcast candle #{c.id}")
      Rujira.Events.publish_edge(:thorchain_tor_candle, "#{c.asset}/#{c.resolution}", c.id)
    end
  end
end
