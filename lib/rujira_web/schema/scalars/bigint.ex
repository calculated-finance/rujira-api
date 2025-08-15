defmodule RujiraWeb.Schema.Scalars.BigInt do
  @moduledoc """
  Defines a custom scalar type for handling large integers in GraphQL.

  This module provides serialization and parsing of large integers, including
  support for both string and integer representations, with special handling
  for Decimal values by converting them to integers with 12 decimal places.
  """
  use Absinthe.Schema.Notation

  @desc """
  The `BigInt` scalar type represents a signed large integer used for representing token amounts or fixed-point decimal values.

  - Can be positive or negative.
  - Token amounts (e.g., balances) are integers already scaled to the token's on-chain precision.
    Example: 10.23 RUJI (8 decimals) → 1023000000
  - Decimal values (e.g., prices) are scaled to 12 decimal places.
    Example: $1.12 → 1120000000000
  - Always returned as a string to preserve precision.
  """

  scalar :bigint do
    parse(&parse_bigint/1)
    serialize(&serialize_bigint/1)
  end

  defp parse_bigint(%Absinthe.Blueprint.Input.String{value: value}) do
    case Integer.parse(value) do
      {int, _} -> {:ok, int}
      _ -> :error
    end
  end

  defp parse_bigint(%Absinthe.Blueprint.Input.Null{}), do: {:ok, nil}

  defp serialize_bigint(value) when is_integer(value), do: Integer.to_string(value)

  defp serialize_bigint(%Decimal{} = value) do
    value
    |> Decimal.mult(1_000_000_000_000)
    |> Decimal.round()
    |> Decimal.to_integer()
    |> Integer.to_string()
  end
end
