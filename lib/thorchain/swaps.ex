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

  @spec total_volume(:all | :daily | :weekly | :monthly) :: integer() | nil
  def total_volume(resolution \\ :all) do
    query =
      case resolution do
        :all ->
          Swap

        resolution ->
          with {:ok, start} <- resolution(DateTime.utc_now(), resolution) do
            from(s in Swap, where: s.timestamp >= ^start)
          end
      end

    (Repo.aggregate(query, :sum, :volume_usd) || 0) |> Decimal.to_integer()
  end

  @spec total_affiliate_volume(:all | :daily | :weekly | :monthly) :: integer()
  def total_affiliate_volume(resolution \\ :all) do
    query =
      case resolution do
        :all ->
          from(s in Swap, where: not is_nil(s.affiliate) and s.affiliate != "")

        resolution ->
          with {:ok, start} <- resolution(DateTime.utc_now(), resolution) do
            from(s in Swap,
              where: s.timestamp >= ^start and not is_nil(s.affiliate) and s.affiliate != ""
            )
          end
      end

    (Repo.aggregate(query, :sum, :volume_usd) || 0) |> Decimal.to_integer()
  end

  defp resolution(now, :daily), do: {:ok, DateTime.add(now, -24 * 60 * 60, :second)}
  defp resolution(now, :weekly), do: {:ok, DateTime.add(now, -7 * 24 * 60 * 60, :second)}
  defp resolution(now, :monthly), do: {:ok, DateTime.add(now, -30 * 24 * 60 * 60, :second)}
  defp resolution(_, _), do: {:error, :invalid}

  def sort(query, dir) do
    order_by(query, [x], [
      {^dir, x.height},
      {^dir, x.tx_idx},
      {^dir, x.idx}
    ])
  end
end
