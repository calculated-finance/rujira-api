defmodule RujiraWeb.Schema.Scalars.BigInt do
  use Absinthe.Schema.Notation

  scalar :bigint, description: "A large integer in ℤ" do
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
  defp serialize_bigint(""), do: nil
  defp serialize_bigint(value) when is_binary(value), do: value

  defp serialize_bigint(%Decimal{} = value) do
    value
    |> Decimal.mult(1_000_000_000_000)
    |> Decimal.round()
    |> Decimal.to_integer()
  end
end
