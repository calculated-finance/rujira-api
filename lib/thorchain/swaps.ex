defmodule Thorchain.Swaps do
  alias Rujira.Repo
  alias Thorchain.Swaps.Swap
  import Ecto.Query

  use GenServer

  def start_link(_) do
    Supervisor.start_link([__MODULE__.Indexer], strategy: :one_for_one)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def insert_swap(params) do
    Swap.changeset(%Swap{}, params)
    |> Repo.insert()
  end

  def count_swaps do
    Swap
    |> Repo.aggregate(:count)
  end

  def count_affiliate_swaps do
    Swap
    |> where([s], not is_nil(s.affiliate) and s.affiliate != "")
    |> Repo.aggregate(:count)
  end

  @spec total_volume(resolution :: :all | :daily | :weekly | :monthly) :: String.t() | nil
  def total_volume(resolution \\ :all) do
    case resolution do
      :all ->
        Swap
        |> select(
          [s],
          fragment(
            "CAST(SUM(CAST(COALESCE(NULLIF(?, ''), '0') AS bigint)) AS TEXT)",
            s.volume_usd
          )
        )
        |> Repo.one()

      resolution ->
        with {:ok, start} <- resolution(DateTime.utc_now(), resolution) do
          Swap
          |> where([s], s.timestamp >= ^start)
          |> select(
            [s],
            fragment(
              "CAST(SUM(CAST(COALESCE(NULLIF(?, ''), '0') AS bigint)) AS TEXT)",
              s.volume_usd
            )
          )
          |> Repo.one()
        end
    end
  end

  @spec total_affiliate_volume(resolution :: :all | :daily | :weekly | :monthly) ::
          String.t() | nil
  def total_affiliate_volume(resolution \\ :all) do
    case resolution do
      :all ->
        Swap
        |> where([s], not is_nil(s.affiliate) and s.affiliate != "")
        |> select(
          [s],
          fragment(
            "CAST(SUM(CAST(COALESCE(NULLIF(?, ''), '0') AS bigint)) AS TEXT)",
            s.volume_usd
          )
        )
        |> Repo.one()

      resolution ->
        with {:ok, start} <- resolution(DateTime.utc_now(), resolution) do
          Swap
          |> where([s], s.timestamp >= ^start)
          |> where([s], not is_nil(s.affiliate) and s.affiliate != "")
          |> select(
            [s],
            fragment(
              "CAST(SUM(CAST(COALESCE(NULLIF(?, ''), '0') AS bigint)) AS TEXT)",
              s.volume_usd
            )
          )
          |> Repo.one()
        end
    end
  end

  defp resolution(now, :daily), do: {:ok, DateTime.add(now, -24 * 60 * 60, :second)}
  defp resolution(now, :weekly), do: {:ok, DateTime.add(now, -7 * 24 * 60 * 60, :second)}
  defp resolution(now, :monthly), do: {:ok, DateTime.add(now, -30 * 24 * 60 * 60, :second)}
  defp resolution(_, _), do: {:error, :invalid}
end
