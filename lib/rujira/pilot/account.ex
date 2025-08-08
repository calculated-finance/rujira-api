defmodule Rujira.Pilot.Account do
  @moduledoc """
  Pilot Account Data
  """

  alias Rujira.Pilot.Bid

  defmodule Summary do
    @moduledoc """
    Pilot Account Bids Summary Data
    """
    defstruct [
      :avg_discount,
      :total_tokens,
      :value,
      :avg_price,
      :total_bids
    ]

    @type t :: %__MODULE__{
            avg_discount: Decimal.t(),
            total_tokens: non_neg_integer(),
            value: non_neg_integer(),
            avg_price: Decimal.t(),
            total_bids: non_neg_integer()
          }

    def from_bids(bids) do
      {allocated_tokens, total_deposits, total_weighted_discount} =
        Enum.reduce(bids, {Decimal.new(0), Decimal.new(0), Decimal.new(0)}, fn bid, {acc, t, w} ->
          total = Decimal.new(bid.offer)
          allocated = checked_div(total, bid.rate)
          weighted_discount = Decimal.mult(bid.premium, bid.offer)
          {Decimal.add(acc, allocated), Decimal.add(t, total), Decimal.add(w, weighted_discount)}
        end)

      avg_price = checked_div(total_deposits, allocated_tokens)
      avg_discount = checked_div(total_weighted_discount, total_deposits)

      {:ok,
       %__MODULE__{
         avg_discount: avg_discount,
         total_tokens: allocated_tokens |> Decimal.round() |> Decimal.to_integer(),
         value: total_deposits |> Decimal.round() |> Decimal.to_integer(),
         avg_price: avg_price,
         total_bids: length(bids)
       }}
    end

    defp checked_div(num, %Decimal{} = denom) do
      if Decimal.eq?(denom, Decimal.new(0)) do
        Decimal.new(0)
      else
        Decimal.div(num, denom)
      end
    end
  end

  defstruct [
    :id,
    :sale,
    :account,
    :bids,
    :history,

    # calculated fields
    :summary
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          sale: String.t(),
          account: String.t(),
          bids: list(Bid.t()),
          history: list(Bid.t()),
          summary: Summary.t()
        }
end
