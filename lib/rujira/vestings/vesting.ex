defmodule Rujira.Vestings.Vesting do
  @moduledoc """
  A single vesting contract, powered by DaoDao vesting contracts.
  """
  defstruct [
    :id,
    :address,
    :creator,
    :status,
    :recipient,
    :title,
    :description,
    :start_time,
    :vested,
    :denom,
    :claimed,
    :slashed,
    :remaining,
    :total
  ]

  @type status :: :unfunded | :funded | :canceled

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          creator: String.t(),
          status: String.t(),
          recipient: String.t(),
          title: String.t(),
          description: String.t(),
          start_time: DateTime.t(),
          # according to wynd_utils is a a fn that defines the vesting schedule
          vested: map(),
          total: non_neg_integer(),
          denom: String.t(),
          claimed: non_neg_integer(),
          slashed: non_neg_integer(),
          remaining: non_neg_integer()
        }

  # Query {info: {}}
  def from_query(address, %{
        "claimed" => claimed,
        "denom" => denom,
        "description" => description,
        "recipient" => recipient,
        "slashed" => slashed,
        "start_time" => start_time,
        "status" => status,
        "title" => title,
        "vested" => vested
      }) do
    with {claimed, ""} <- Integer.parse(claimed),
         {slashed, ""} <- Integer.parse(slashed),
         {start_time, ""} <- Integer.parse(start_time),
         {:ok, start_time} <- DateTime.from_unix(start_time, :nanosecond),
         {:ok, denom} <- parse_denom(denom),
         {:ok, {total, vested}} <- parse_vested(vested) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         status: parse_status(status),
         recipient: recipient,
         title: title,
         description: description,
         start_time: start_time,
         vested: vested,
         total: total,
         denom: denom,
         claimed: claimed,
         slashed: slashed,
         remaining: total - claimed - slashed
       }}
    end
  end

  defp parse_denom(%{"native" => denom}), do: {:ok, denom}

  defp parse_status("funded"), do: :funded
  defp parse_status("unfunded"), do: :unfunded
  defp parse_status("canceled"), do: :canceled

  defp parse_vested(%{
         "saturating_linear" => %{
           "max_x" => max_x,
           "max_y" => max_y,
           "min_x" => min_x,
           "min_y" => min_y
         }
       }) do
    with {max_y, ""} <- Integer.parse(max_y),
         {min_y, ""} <- Integer.parse(min_y) do
      {:ok,
       {max_y,
        %{
          type: :saturating_linear,
          max_x: max_x,
          max_y: max_y,
          min_x: min_x,
          min_y: min_y
        }}}
    end
  end

  defp parse_vested(_), do: {:ok, {Integer.parse(0), nil}}
end
