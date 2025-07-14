defmodule Rujira.Analytics.Swap.AddressBin do
  @moduledoc """
  The Swap.AddressBin schema is used to collect analytics for unique addresses that participate
  in swaps on the base layer with a specific affiliate.

  This table stores data that is critical for analyzing:

    - Unique addresses during a specific bin period.
    - Churn metrics.
    - Month-to-month retention rates.

  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Rujira.Repo

  @type t :: %__MODULE__{
          resolution: String.t(),
          bin: DateTime.t(),
          affiliate: String.t(),
          address: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  # understand unique addresses per affiliate per bin
  # if there are more than 1 affiliate we weight the address by the affiliate with the bps
  #  example: 2 affiliates 20/30
  #  address 1: 0.40
  #  address 2: 0.60
  #  total: 1.00
  #  address 1: 20/50 = 40%
  #  address 2: 30/50 = 60%
  @primary_key false
  schema "thorchain_swap_address_bins" do
    field :resolution, :string, primary_key: true
    field :bin, :utc_datetime, primary_key: true
    field :affiliate, :string, primary_key: true
    field :address, :string, primary_key: true

    field :address_weight, :decimal

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(bin, attrs) do
    bin
    |> cast(attrs, [:resolution, :bin, :address, :affiliate, :count])
    |> validate_required([:resolution, :bin, :address, :affiliate, :count])
  end

  def update(entries) do
    sanitized = sanitize(entries)

    __MODULE__
    |> Repo.insert_all(
      sanitized,
      on_conflict: :nothing,
      conflict_target: [:resolution, :bin, :address, :affiliate],
      returning: true
    )
  end

  defp sanitize(entries) do
    group_keys = [:resolution, :bin, :affiliate, :address]
    fields = __MODULE__.__schema__(:fields)

    entries
    |> Enum.map(&Map.take(&1, fields))
    |> Enum.group_by(fn entry ->
      Map.take(entry, group_keys)
    end)
    |> Enum.map(fn {_, group_entries} ->
      base = hd(group_entries)

      address_weight =
        group_entries
        |> Enum.map(& &1.address_weight)
        |> Enum.reduce(Decimal.new(0), fn weight, acc ->
          Decimal.add(acc, weight)
        end)

      Map.put(base, :address_weight, address_weight)
    end)
  end
end
