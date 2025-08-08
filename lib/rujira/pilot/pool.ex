defmodule Rujira.Pilot.Pool do
  @moduledoc """
  This module parses the pool data from the Pilot contract into a the correct Rujira Pilot struct
  """
  defstruct [
    :slot,
    :premium,
    :rate,
    :epoch,
    :total
  ]

  @type t :: %__MODULE__{
          slot: non_neg_integer(),
          premium: non_neg_integer(),
          rate: Decimal.t(),
          epoch: non_neg_integer(),
          total: non_neg_integer()
        }

  def from_query(%{
        "price" => price,
        # it's already an integer
        "premium" => premium,
        # it's already an integer
        "epoch" => epoch,
        "total" => total
      }) do
    with {total, ""} <- Integer.parse(total),
         {price, ""} <- Decimal.parse(price) do
      {:ok,
       %__MODULE__{
         slot: premium,
         premium: premium,
         rate: price,
         epoch: epoch,
         total: total
       }}
    end
  end
end
