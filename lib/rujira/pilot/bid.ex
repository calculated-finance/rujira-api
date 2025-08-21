defmodule Rujira.Pilot.Bid do
  @moduledoc """
  This module parses the order data of one account of one sale contract into a the correct Rujira Pilot Bid struct
  """
  defstruct [:id, :sale, :owner, :premium, :slot, :rate, :offer, :remaining, :filled, :updated_at]

  @type t :: %__MODULE__{
          id: String.t(),
          sale: String.t(),
          owner: String.t(),
          premium: non_neg_integer(),
          slot: non_neg_integer(),
          rate: Decimal.t(),
          offer: non_neg_integer(),
          remaining: non_neg_integer(),
          filled: non_neg_integer(),
          updated_at: DateTime.t()
        }

  def from_query(%{address: address}, %{
        "owner" => owner,
        "premium" => premium,
        "rate" => rate,
        "offer" => offer,
        "remaining" => remaining,
        "filled" => filled,
        "updated_at" => updated_at
      }) do
    with {offer, ""} <- Integer.parse(offer),
         {remaining, ""} <- Integer.parse(remaining),
         {filled, ""} <- Integer.parse(filled),
         {rate, ""} <- Decimal.parse(rate),
         {updated_at, ""} <- Integer.parse(updated_at),
         {:ok, updated_at} <- DateTime.from_unix(updated_at, :nanosecond) do
      {:ok,
       %__MODULE__{
         id: "#{address}/#{owner}/#{premium}",
         sale: address,
         owner: owner,
         premium: premium,
         slot: premium,
         rate: rate,
         offer: offer,
         remaining: remaining,
         filled: filled,
         updated_at: updated_at
       }}
    end
  end
end
