defmodule RujiraWeb.Schema.Scalars.Address do
  @moduledoc """
  Defines a custom scalar type for blockchain addresses in GraphQL.

  This module handles the validation and serialization of blockchain addresses,
  ensuring they are properly formatted as strings. It accepts string inputs
  representing blockchain addresses and returns them as-is, or nil for invalid values.
  """
  use Absinthe.Schema.Notation

  scalar :address, description: "An address associated with a blockchain account/public key" do
    parse(&do_parse/1)
    serialize(&do_serialize/1)
  end

  defp do_parse(%Absinthe.Blueprint.Input.String{value: value}), do: {:ok, value}
  defp do_parse(%Absinthe.Blueprint.Input.Null{}), do: {:ok, nil}
  defp do_parse(_), do: :error

  defp do_serialize(value) when is_binary(value), do: value
  defp do_serialize(_), do: nil
end
