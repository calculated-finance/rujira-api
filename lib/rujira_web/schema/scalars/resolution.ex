defmodule RujiraWeb.Schema.Scalars.Resolution do
  use Absinthe.Schema.Notation
  alias Absinthe.Blueprint.Input

  @resolutions ["1", "3", "5", "15", "30", "60", "120", "180", "240", "1D", "1M", "12M"]

  @desc """
  The `Resolution` scalar type represents a time interval. It is a string that
  can be one of the following values:

  1. "1" - 1 minute
  2. "3" - 3 minutes
  3. "5" - 5 minutes
  4. "15" - 15 minutes
  5. "30" - 30 minutes
  6. "60" - 1 hour
  7. "120" - 2 hours
  8. "180" - 3 hours
  9. "240" - 4 hours
  10. "1D" - 1 day
  11. "1M" - 1 month
  12. "12M" - 12 months
  """
  scalar :resolution do
    serialize(&serialize_string/1)
    parse(&parse_string/1)
  end

  defp serialize_string(value) when value in @resolutions, do: value
  defp serialize_string(_), do: :error

  defp parse_string(%Input.String{value: value}) do
    if value in @resolutions do
      {:ok, value}
    else
      :error
    end
  end

  defp parse_string(%Input.Null{}) do
    {:ok, nil}
  end

  defp parse_string(_) do
    :error
  end
end
