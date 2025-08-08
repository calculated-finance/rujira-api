defmodule Rujira.Keiko.Tokenomics.Stream do
  @moduledoc """
  This module provides the type definition and parsing logic for a Tokenomics stream used by the Keiko deployment orchestrator.
  """

  defstruct [
    :owner,
    :recipient,
    :title,
    :total,
    :denom,
    :start_time,
    :schedule,
    :vesting_duration_seconds,
    :unbonding_duration_seconds
  ]

  @type t :: %__MODULE__{
          owner: String.t() | nil,
          recipient: String.t(),
          title: String.t(),
          total: non_neg_integer(),
          denom: String.t(),
          start_time: DateTime.t(),
          schedule: String.t(),
          vesting_duration_seconds: non_neg_integer(),
          unbonding_duration_seconds: non_neg_integer()
        }

  def from_query(%{
        "owner" => owner,
        "recipient" => recipient,
        "title" => title,
        "total" => total,
        "denom" => %{"native" => denom},
        "start_time" => start_time,
        "schedule" => schedule,
        "vesting_duration_seconds" => vesting_duration_seconds,
        "unbonding_duration_seconds" => unbonding_duration_seconds
      }) do
    with {total, ""} <- Integer.parse(total),
         {start_time, ""} <- Integer.parse(start_time),
         {:ok, start_time} <- DateTime.from_unix(start_time, :nanosecond) do
      {:ok,
       %__MODULE__{
         owner: owner,
         recipient: recipient,
         title: title,
         total: total,
         denom: denom,
         start_time: start_time,
         schedule: schedule,
         vesting_duration_seconds: vesting_duration_seconds,
         unbonding_duration_seconds: unbonding_duration_seconds
       }}
    end
  end
end
