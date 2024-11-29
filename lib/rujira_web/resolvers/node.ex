defmodule RujiraWeb.Resolvers.Node do
  alias Rujira.Accounts.Account
  alias Rujira.Accounts.Layer1

  def id(%{id: encoded_id}, _) do
    decode_id(encoded_id)
  end

  def list(_, %{ids: ids}, _) do
    Enum.reduce(ids, {:ok, []}, fn id, agg ->
      with {:ok, agg} <- agg,
           {:ok, id} <- decode_id(id) do
        {:ok, [id | agg]}
      end
    end)
  end

  def type(%Account{}, _), do: :account
  def type(%Layer1{}, _), do: :layer_1_account

  defp decode_id(id) do
    case String.split(id, ":") do
      ["account", "kujira", address] ->
        # Special case for Kujira so we can query native merge assets
        {:ok,
         %Account{
           chain: :kujira,
           address: address
         }}

      ["account", chain, address] ->
        {:ok,
         %Layer1{
           chain: String.to_existing_atom(chain),
           address: address
         }}

      ["account", address] ->
        {:ok, %Account{chain: :thor, address: address}}

      _ ->
        {:error, "Invalid ID"}
    end
  end
end
