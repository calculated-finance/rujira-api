defmodule RujiraWeb.Schema.Scalars.Timestamp do
  use Absinthe.Schema.Notation
  alias Absinthe.Blueprint.Input

  @desc """
  The `Timestamp` scalar type represents a date and time in the UTC
  timezone. The DateTime appears in a JSON response as an ISO8601 formatted
  string, including UTC timezone ("Z"). The parsed date and time string will
  be converted to UTC and any UTC offset other than 0 will be rejected.
  """
  scalar :timestamp, name: "Timestamp" do
    serialize(&DateTime.to_iso8601/1)
    parse(&parse_datetime/1)
  end

  defp parse_datetime(%Input.String{value: value}) do
    DateTime.from_unix(value)
  end

  defp parse_datetime(%Input.Null{}) do
    {:ok, nil}
  end

  defp parse_datetime(_) do
    :error
  end
end
