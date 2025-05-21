defmodule Rujira.Merge.Pool do
  defmodule Status do
    alias Rujira.Chains.Thor
    alias Rujira.Merge.Pool

    defstruct [
      :merged,
      :shares,
      :size,
      :current_rate,
      :share_value,
      :share_value_change,
      :apr
    ]

    @type t :: %__MODULE__{
            merged: integer(),
            shares: integer(),
            size: integer(),
            current_rate: integer(),
            share_value: Decimal.t(),
            share_value_change: non_neg_integer(),
            apr: Decimal.t()
          }

    @spec from_query(Pool.t(), map()) :: {:ok, __MODULE__.t()} | {:error, :parse_error}
    def from_query(pool, %{"merged" => merged, "shares" => shares, "size" => size}) do
      with {:ok, _balance} <- Thor.balance_of(pool.address, pool.ruji_denom),
           {merged, ""} <- Integer.parse(merged),
           {shares, ""} <- Integer.parse(shares),
           {size, ""} <- Integer.parse(size) do
        # max = balance - size
        # apr = Decimal.new(max)

        {:ok, %__MODULE__{merged: merged, shares: shares, size: size}}
      else
        _ -> {:error, :parse_error}
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
          decay_starts_at: DateTime.t(),
          decay_ends_at: DateTime.t(),
          start_rate: Decimal.t(),
          current_rate: Decimal.t(),
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
         {decay_ends_at, ""} <- Integer.parse(decay_ends_at),
         {decay_starts_at, ""} <- Integer.parse(decay_starts_at),
         {:ok, decay_ends_at} <- DateTime.from_unix(decay_ends_at, :nanosecond),
         {:ok, decay_starts_at} <- DateTime.from_unix(decay_starts_at, :nanosecond) do
      start_rate = ruji_allocation |> Decimal.new() |> Decimal.div(Decimal.new(merge_supply))

      %__MODULE__{
        id: address,
        address: address,
        merge_denom: merge_denom,
        merge_supply: merge_supply,
        ruji_denom: ruji_denom,
        ruji_allocation: ruji_allocation,
        decay_starts_at: decay_starts_at,
        decay_ends_at: decay_ends_at,
        start_rate: start_rate,
        status: :not_loaded
      }
      |> set_rate()
      |> then(&{:ok, &1})
    else
      _ -> :error
    end
  end

  def set_rate(
        %__MODULE__{status: %Status{shares: shares, size: size} = status} =
          pool
      ) do
    current_rate = calculate_rate(pool)

    share_value =
      if shares == 0,
        do: Decimal.new(1),
        else:
          size
          |> Decimal.new()
          |> Decimal.div(Decimal.new(shares))

    share_value_change = Decimal.sub(share_value, Decimal.new(1))

    %{
      pool
      | current_rate: current_rate,
        status: %{
          status
          | current_rate: current_rate,
            share_value: share_value,
            share_value_change: share_value_change
        }
    }
  end

  def set_rate(%__MODULE__{} = pool) do
    current_rate = calculate_rate(pool)
    %{pool | current_rate: current_rate}
  end

  defp calculate_rate(%__MODULE__{
         decay_ends_at: decay_ends_at,
         decay_starts_at: decay_starts_at,
         start_rate: start_rate
       }) do
    now = DateTime.utc_now()
    remaining_time = DateTime.diff(decay_ends_at, now, :second)
    duration = DateTime.diff(decay_ends_at, decay_starts_at, :second)

    cond do
      DateTime.compare(now, decay_starts_at) == :lt ->
        start_rate

      DateTime.compare(now, decay_ends_at) == :gt ->
        0

      true ->
        remaining_time
        |> Decimal.new()
        |> Decimal.div(Decimal.new(duration))
        |> Decimal.mult(start_rate)
    end
  end
end
