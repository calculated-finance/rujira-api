defmodule Rujira.Fin.Order do
  alias Rujira.Fin.Pair

  defstruct [
    :id,
    :pair,
    :owner,
    :side,
    :type,
    :deviation,
    :rate,
    :updated_at,
    :offer,
    :remaining,
    :filled
  ]

  @type side :: :base | :quote
  @type deviation :: nil | integer()
  @type type_order :: :fixed | :oracle
  @type t :: %__MODULE__{
          pair: String.t(),
          owner: String.t(),
          side: side,
          rate: Decimal.t(),
          updated_at: DateTime.t(),
          offer: integer(),
          remaining: integer(),
          filled: integer(),
          type: type_order,
          deviation: deviation
        }

  def from_query(%Pair{address: pair_address}, %{
        "owner" => owner,
        "side" => side,
        "price" => price,
        "rate" => rate,
        "updated_at" => updated_at,
        "offer" => offer,
        "remaining" => remaining,
        "filled" => filled
      }) do
    with {type, deviation, price} <- parse_price(price),
         {rate, ""} <- Decimal.parse(rate),
         {updated_at, ""} <- Integer.parse(updated_at),
         {:ok, updated_at} <- DateTime.from_unix(updated_at, :nanosecond),
         {offer, ""} <- Integer.parse(offer),
         {remaining, ""} <- Integer.parse(remaining),
         {filled, ""} <- Integer.parse(filled) do
      %__MODULE__{
        id: "contract:fin:#{pair_address}:order:#{price}",
        pair: pair_address,
        owner: owner,
        side: String.to_atom(side),
        rate: rate,
        updated_at: updated_at,
        offer: offer,
        remaining: remaining,
        filled: filled,
        type: type,
        deviation: deviation
      }
    end
  end

  def parse_price(%{"fixed" => v}), do: {:fixed, nil, "fixed/#{v}"}
  def parse_price(%{"oracle" => deviation}), do: {:oracle, deviation, "oracle/#{deviation}"}
end
