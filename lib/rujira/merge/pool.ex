defmodule Rujira.Merge.Pool do
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
    :address,
    :merge_denom,
    :merge_supply,
    :ruji_denom,
    :ruji_allocation,
    :decay_starts_at,
    :decay_ends_at,
    :status
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          merge_denom: String.t(),
          merge_supply: integer(),
          ruji_denom: String.t(),
          ruji_allocation: integer(),
          decay_starts_at: integer(),
          decay_ends_at: integer(),
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
      {:ok,
       %__MODULE__{
         address: address,
         merge_denom: merge_denom,
         merge_supply: merge_supply,
         ruji_denom: ruji_denom,
         ruji_allocation: ruji_allocation,
         decay_starts_at: decay_starts_at,
         decay_ends_at: decay_ends_at,
         status: :not_loaded
       }}
    else
      _ -> :error
    end
  end
end
