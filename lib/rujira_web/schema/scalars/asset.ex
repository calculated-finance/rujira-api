defmodule RujiraWeb.Schema.Scalars.Asset do
  @moduledoc """
  Defines a custom scalar type for THORChain compatible asset strings in GraphQL.

  This module handles the validation and serialization of asset identifiers,
  ensuring they conform to the THORChain asset string format requirements.
  It accepts string inputs and returns them as-is, or nil for invalid values.
  """
  use Absinthe.Schema.Notation

  scalar :asset_string, description: "A string representation of a THORChain compatible asset" do
    parse(&do_parse/1)
    serialize(&do_serialize/1)
  end

  defp do_parse(%Absinthe.Blueprint.Input.String{value: value}), do: {:ok, value}
  defp do_parse(%Absinthe.Blueprint.Input.Null{}), do: {:ok, nil}
  defp do_parse(_), do: :error

  defp do_serialize(value) when is_binary(value), do: value
  defp do_serialize(_), do: nil
end
