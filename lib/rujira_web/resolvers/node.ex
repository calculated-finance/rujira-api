defmodule RujiraWeb.Resolvers.Node do
  alias Rujira.Tokens.Asset
  alias Rujira.Tokens.Denom
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
  def type(%Denom{}, _), do: :denom
  def type(%Asset{}, _), do: :layer_1_asset

  defp decode_id(id) do
    case String.split(id, ":") do
      ["account", chain, address] ->
        try do
          {:ok,
           %Layer1{
             id: id,
             chain: String.to_existing_atom(chain),
             address: address
           }}
        rescue
          ArgumentError -> {:error, "invalid chain #{chain}"}
        end

      ["account", address] ->
        {:ok, %Account{id: id, chain: :thor, address: address}}

      ["token", "asset", asset] ->
        {:ok, %Asset{id: id, asset: asset}}

      ["token", "denom", denom] ->
        {:ok, %Denom{id: id, denom: denom}}

      _ ->
        {:error, "Invalid ID"}
    end
  end
end
