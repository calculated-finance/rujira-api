# test/support/graphql_helpers.ex
defmodule RujiraWeb.Schema.GraphQLHelpers do
  @moduledoc """
  Helpers for asserting that a returned JSON map (with camelCased keys) has
  all the fields specified in the Absinthe schema (which are in snake_case).
  """

  import ExUnit.Assertions
  alias RujiraWeb.Schema
  alias Absinthe.Type

  @doc """
  Given a JSON map where keys are strings in camelCase (e.g. "chainLpActionsPaused"),
  assert that it contains at least all of the fields defined on `type_name`
  (in snake_case) within `RujiraWeb.Schema`.

  Steps:
    1. Pull the `%Type.Object{fields: fields_map}` for `type_name`.
    2. Convert those field‐keys (atoms) to strings, then drop `"__typename"` if present.
    3. Take the returned_map’s keys (camelCased strings), convert each to snake_case:
         e.g. "chainLpActionsPaused" → "chain_lp_actions_paused"
    4. Ensure there are no missing fields. Extra returned keys are permitted.
  """
  def assert_map_has_fields!(returned_map, type_name) when is_map(returned_map) do
    # 1. Look up the object‐type in the Absinthe schema
    case Absinthe.Schema.lookup_type(Schema, type_name) do
      %Type.Object{fields: fields_map} ->
        # 2. Build a list of expected fields (as strings), dropping "__typename"
        expected_fields =
          fields_map
          |> Map.keys()                          # [:address, :chain_lp_actions_paused, ...]
          |> Enum.map(&Atom.to_string/1)         # ["address", "chain_lp_actions_paused", ...]
          |> Enum.reject(&(&1 == "__typename"))  # remove __typename if it was generated
          |> Enum.sort()

        # 3. Convert returned_map’s camelCase keys → snake_case strings
        actual_fields =
          returned_map
          |> Map.keys()                          # ["address", "chainLpActionsPaused", ...]
          |> Enum.map(&camel_to_snake/1)         # ["address", "chain_lp_actions_paused", ...]
          |> Enum.sort()

        # 4. Check for missing fields
        missing = expected_fields -- actual_fields

        if missing == [] do
          :ok
        else
          flunk("""
          Returned JSON for type #{inspect(type_name)} is missing fields: #{inspect(missing)}.

          Expected at least: #{inspect(expected_fields)}
          Actual snake_cased keys: #{inspect(actual_fields)}
          """)
        end

      nil ->
        flunk("Cannot find type #{inspect(type_name)} in schema #{inspect(Schema)}")
    end
  end

  # Helpers

  # Convert a camelCase string to snake_case:
  #   "chainLpActionsPaused" -> "chain_lp_actions_paused"
  defp camel_to_snake(camel) when is_binary(camel) do
    camel
    |> String.replace(~r/([a-z0-9])([A-Z])/, "\\1_\\2")
    |> String.replace(~r/([A-Z])([A-Z][a-z])/, "\\1_\\2")
    |> String.downcase()
  end
end
