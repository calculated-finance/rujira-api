defmodule Rujira.Merge.Pool do
  @precision 1_000_000_000_000

  defmodule Status do
    defstruct [
      :merged,
      :shares,
      :size
    ]

    @type t :: %__MODULE__{
            merged: integer(),
            shares: integer(),
            size: integer()
          }

    @spec from_query(map()) :: {:ok, __MODULE__.t()} | :error
    def from_query(%{
          "merged" => merged,
          "shares" => shares,
          "size" => size
        }) do
      with {merged, ""} <- Integer.parse(merged),
           {shares, ""} <- Integer.parse(shares),
           {size, ""} <- Integer.parse(size) do
        {:ok,
         %__MODULE__{
           merged: merged,
           shares: shares,
           size: size
         }}
      else
        _ -> :error
      end
    end
  end

  defstruct [
    :id,
    :address,
    :merge_denom,
    :merge_supply,
    :ruji_denom,
    :ruji_allocation,
    :decay_starts_at,
    :decay_ends_at,
    :start_rate,
    :current_rate,
    :status
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          merge_denom: String.t(),
          merge_supply: integer(),
          ruji_denom: String.t(),
          ruji_allocation: integer(),
          decay_starts_at: integer(),
          decay_ends_at: integer(),
          start_rate: integer(),
          current_rate: integer(),
          status: :not_loaded | Status.t()
        }

  @spec from_config(String.t(), map()) :: :error | {:ok, __MODULE__.t()}
  def from_config(address, %{
        "merge_denom" => merge_denom,
        "merge_supply" => merge_supply,
        "ruji_denom" => ruji_denom,
        "ruji_allocation" => ruji_allocation,
        "decay_starts_at" => decay_starts_at,
        "decay_ends_at" => decay_ends_at
      }) do
    with {merge_supply, ""} <- Integer.parse(merge_supply),
         {ruji_allocation, ""} <- Integer.parse(ruji_allocation),
         {:ok, decay_ends_at} <- Rujira.parse_timestamp(decay_ends_at),
         {:ok, decay_starts_at} <- Rujira.parse_timestamp(decay_starts_at) do
      %__MODULE__{
        address: address,
        merge_denom: merge_denom,
        merge_supply: merge_supply,
        ruji_denom: ruji_denom,
        ruji_allocation: ruji_allocation,
        decay_starts_at: decay_starts_at,
        decay_ends_at: decay_ends_at,
        status: :not_loaded
      }
      |> set_rates()
      |> then(&{:ok, &1})
    else
      _ -> :error
    end
  end

  defp set_rates(
         %__MODULE__{
           merge_denom: merge_denom,
           merge_supply: merge_supply,
           ruji_allocation: ruji_allocation,
           decay_ends_at: decay_ends_at,
           decay_starts_at: decay_starts_at
         } = pool
       ) do
    now = DateTime.utc_now()
    remaining_time = DateTime.diff(decay_ends_at, now, :second)
    duration = DateTime.diff(decay_ends_at, decay_starts_at, :second)
    start_rate = trunc(div(ruji_allocation * @precision, merge_supply))

    current_rate =
      cond do
        DateTime.compare(now, decay_starts_at) == :lt -> start_rate
        DateTime.compare(now, decay_ends_at) == :gt -> 0
        true -> trunc(div(start_rate, @precision) * div(remaining_time * @precision, duration))
      end

    %{pool | start_rate: start_rate, current_rate: current_rate}
  end
end
