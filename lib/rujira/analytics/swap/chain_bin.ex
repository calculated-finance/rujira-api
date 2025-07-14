defmodule Rujira.Analytics.Swap.ChainBin do
  @moduledoc """
  The ChainBin schema aggregates base layer swap data at the blockchain chain level within defined time intervals (bins).
  This schema is crucial for analyzing swap activity across different chains and understanding their individual contributions
  to the overall base layer ecosystem. Key insights provided include:

    - Volume Breakdown: Total swap volume aggregated for each chain.
    - Chain Performance: Identification of chains with higher swap activity, indicating potential revenue and impact.
    - Trend Analysis: Monitoring changes in swap volumes over time per chain, supporting strategic and operational decisions.

  This granular breakdown supports a deeper understanding of how each chain performs in the context of base layer swaps,
  thereby enabling data-driven decisions for optimizing liquidity and revenue strategies.
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Rujira.Repo
  import Ecto.Query

  @type t :: %__MODULE__{
          resolution: String.t(),
          bin: DateTime.t(),
          affiliate: String.t(),
          source_chain: String.t(),
          volume: non_neg_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  # this is calculating the total volume per chain per bin from a specific affiliate
  # if more than 1 affiliate is associated with 1 swap, we weight the data by the affiliate with the bps
  @primary_key false
  schema "thorchain_swap_chain_bins" do
    field :resolution, :string, primary_key: true
    field :bin, :utc_datetime, primary_key: true
    field :affiliate, :string, primary_key: true
    field :source_chain, :string, primary_key: true

    field :volume, :integer

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(bin, attrs) do
    bin
    |> cast(attrs, [:resolution, :bin, :affiliate, :source_chain, :volume])
    |> validate_required([:resolution, :bin, :affiliate, :source_chain, :volume])
  end

  def update(entries) do
    sanitized = sanitize(entries)

    __MODULE__
    |> Repo.insert_all(
      sanitized,
      on_conflict: handle_conflict(),
      conflict_target: [:resolution, :bin, :affiliate, :source_chain],
      returning: true
    )
  end

  defp handle_conflict do
    from(c in __MODULE__,
      update: [
        set: [
          volume: fragment("EXCLUDED.volume + ?", c.volume)
        ]
      ]
    )
  end

  defp sanitize(entries) do
    group_keys = [:resolution, :bin, :affiliate, :source_chain]
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

      Map.put(base, :volume, sum_volume)
    end)
  end
end
