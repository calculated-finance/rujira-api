defmodule Rujira.Analytics.Swap.AffiliateBin do
  @moduledoc """
  The AffiliateBin schema aggregates base layer swap data to evaluate the contribution of each affiliate
  to the base layer ecosystem.

    - Total Swaps: The number of swap transactions executed.
    - Liquidity Fee: The fees collected from liquidity provision, indicating the affiliate's impact
      on overall liquidity.
    - Revenue Generated: The revenue earned by the affiliate from these swap transactions.

  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Rujira.Repo
  import Ecto.Query

  @type t :: %__MODULE__{
          resolution: String.t(),
          bin: DateTime.t(),
          affiliate: String.t(),
          count: non_neg_integer(),
          revenue: non_neg_integer(),
          liquidity_fee: non_neg_integer(),
          volume: non_neg_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  # this is calculating the total n.swap, revenue, liquidity_fee, volume per affiliate per bin
  # if more than 1 affiliate is associated with 1 swap, we weight the data by the affiliate with the bps
  @primary_key false
  schema "thorchain_swap_affiliate_bins" do
    field :resolution, :string, primary_key: true
    field :bin, :utc_datetime, primary_key: true
    field :affiliate, :string, primary_key: true

    # 2 leg swaps are accounted as 2 swaps
    field :count, :decimal
    field :revenue, :integer
    field :liquidity_fee, :integer
    field :volume, :integer

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(bin, attrs) do
    bin
    |> cast(attrs, [
      :resolution,
      :bin,
      :affiliate,
      :revenue,
      :liquidity_fee,
      :volume
    ])
    |> validate_required([
      :resolution,
      :bin,
      :affiliate,
      :revenue,
      :liquidity_fee,
      :volume
    ])
  end

  def update(entries) do
    sanitized = sanitize(entries)

    __MODULE__
    |> Repo.insert_all(
      sanitized,
      on_conflict: handle_conflict(),
      conflict_target: [:resolution, :bin, :affiliate],
      returning: true
    )
  end

  defp handle_conflict do
    from(c in __MODULE__,
      update: [
        set: [
          count: fragment("EXCLUDED.count + ?", c.count),
          revenue: fragment("EXCLUDED.revenue + ?", c.revenue),
          liquidity_fee: fragment("EXCLUDED.liquidity_fee + ?", c.liquidity_fee),
          volume: fragment("EXCLUDED.volume + ?", c.volume)
        ]
      ]
    )
  end

  defp sanitize(entries) do
    group_keys = [:resolution, :bin, :affiliate]
    fields = __MODULE__.__schema__(:fields)

    entries
    |> Enum.map(&Map.take(&1, fields))
    |> Enum.group_by(fn entry ->
      Map.take(entry, group_keys)
    end)
    |> Enum.map(fn {_, group_entries} ->
      base = hd(group_entries)

      sum_volume =
        group_entries
        |> Enum.map(& &1.volume)
        |> Enum.reduce(0, &Kernel.+/2)

      sum_revenue =
        group_entries
        |> Enum.map(& &1.revenue)
        |> Enum.reduce(0, &Kernel.+/2)

      sum_liquidity_fee =
        group_entries
        |> Enum.map(& &1.liquidity_fee)
        |> Enum.reduce(0, &Kernel.+/2)

      sum_count =
        group_entries
        |> Enum.map(& &1.count)
        |> Enum.reduce(Decimal.new(0), fn count, acc ->
          Decimal.add(acc, count)
        end)

      Map.put(base, :volume, sum_volume)
      |> Map.put(:revenue, sum_revenue)
      |> Map.put(:liquidity_fee, sum_liquidity_fee)
      |> Map.put(:count, sum_count)
    end)
  end
end
