defmodule RujiraWeb.Schema.Scalars.Timestamp do
  @moduledoc """
  Defines a custom scalar type for handling timestamps in GraphQL.

  This module provides serialization and parsing of ISO8601 formatted datetime strings
  to and from Elixir's `DateTime` structs, ensuring UTC timezone handling.
  """
  use Absinthe.Schema.Notation
  alias Absinthe.Blueprint.Input

  @desc """
  The `Timestamp` scalar type represents a date and time in the UTC
  timezone. The DateTime appears in a JSON response as an ISO8601 formatted
  string, including UTC timezone ("Z"). The parsed date and time string will
  be converted to UTC and any UTC offset other than 0 will be rejected.

  Example:
  "2025-06-19T15:30:00Z"
  """
  scalar :timestamp, name: "Timestamp" do
    serialize(&serialize_datetime/1)
    parse(&parse_datetime/1)
  end

  defp parse_datetime(%Input.String{value: value}) do
    with {:ok, ts, 0} <- DateTime.from_iso8601(value) do
      {:ok, ts}
    end
  end

  defp parse_datetime(%Input.Null{}) do
    {:ok, nil}
  end

  defp parse_datetime(_) do
    :error
  end

  defp serialize_datetime(%NaiveDateTime{} = value) do
    with {:ok, ts} <- DateTime.from_naive(value, "Etc/UTC") do
      DateTime.to_iso8601(ts)
    end
  end

  defp serialize_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
