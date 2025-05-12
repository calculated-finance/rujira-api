defmodule Rujira.Fin.Order do
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
    :offer_value,
    :remaining,
    :remaining_value,
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
          offer_value: integer(),
          remaining: integer(),
          remaining_value: integer(),
          filled: integer(),
          type: type_order,
          deviation: deviation
        }

  def from_query(pair_address, %{
        "owner" => owner,
        "side" => side,
        "price" => price,
        "rate" => rate,
        "updated_at" => updated_at,
        "offer" => offer,
        "remaining" => remaining,
        "filled" => filled
      }) do
    with {type, deviation, price_id} <- parse_price(price),
         {rate, ""} <- Decimal.parse(rate),
         {updated_at, ""} <- Integer.parse(updated_at),
         {:ok, updated_at} <- DateTime.from_unix(updated_at, :nanosecond),
         {offer, ""} <- Integer.parse(offer),
         {remaining, ""} <- Integer.parse(remaining),
         {filled, ""} <- Integer.parse(filled) do
      side = String.to_existing_atom(side)

      %__MODULE__{
        id: "#{pair_address}/#{side}/#{price_id}/#{owner}",
        pair: pair_address,
        owner: owner,
        side: side,
        rate: rate,
        updated_at: updated_at,
        offer: offer,
        offer_value: value(offer, rate, side),
        remaining: remaining,
        remaining_value: value(remaining, rate, side),
        filled: filled,
        type: type,
        deviation: deviation
      }
    end
  end

  def parse_price(%{"fixed" => v}), do: {:fixed, nil, "fixed:#{v}"}
  def parse_price(%{"oracle" => v}), do: {:oracle, v, "oracle:#{v}"}
  def decode_price("fixed:" <> v), do: %{fixed: v}
  def decode_price("oracle:" <> v), do: %{oracle: v}
  def encode_price(%{fixed: v}), do: "fixed:#{v}"
  def encode_price(%{oracle: v}), do: "oracle:#{v}"

  def from_id(id) do
    [pair_address, side, price, owner] = String.split(id, "/")
    load(pair_address, side, price, owner)
  end

  def load(pair_address, side, price, owner) do
    with {:ok, order} <-
           Rujira.Contracts.query_state_smart(
             pair_address,
             %{order: [owner, side, decode_price(price)]}
           ) do
      {:ok, from_query(pair_address, order)}
    else
      {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}} ->
        [type | _] = String.split(price, ":")

        {:ok,
         %__MODULE__{
           id: "#{pair_address}/#{side}/#{price}/#{owner}",
           pair: pair_address,
           owner: owner,
           side: String.to_existing_atom(side),
           rate: 0,
           updated_at: DateTime.utc_now(),
           offer: 0,
           remaining: 0,
           filled: 0,
           type: type,
           deviation: nil
         }}

      err ->
        err
    end
  end

  defp value(amount, rate, :base) do
    amount
    |> Decimal.new()
    |> Decimal.mult(rate)
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end

  defp value(amount, rate, :quote) do
    amount
    |> Decimal.new()
    |> Decimal.div(rate)
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end
end
