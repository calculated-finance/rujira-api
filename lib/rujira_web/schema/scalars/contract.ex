defmodule RujiraWeb.Schema.Scalars.Contract do
  use Absinthe.Schema.Notation

  scalar :contract, description: "An address associated with a blockchain smart contract" do
    parse(&do_parse/1)
    serialize(&do_serialize/1)
  end

  defp do_parse(%Absinthe.Blueprint.Input.String{value: value}), do: {:ok, value}
  defp do_parse(_), do: :error

  defp do_serialize(value) when is_binary(value), do: value
  defp do_serialize(_), do: nil
end
