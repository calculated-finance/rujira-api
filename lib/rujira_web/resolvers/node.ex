defmodule RujiraWeb.Resolvers.Node do
  alias Rujira.Assets
  alias Rujira.Denoms
  alias Rujira.Accounts
  alias Rujira.Merge

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

  def type(%Accounts.Account{}, _), do: :account
  def type(%Accounts.Layer1{}, _), do: :layer_1_account
  def type(%Denoms.Denom{}, _), do: :denom
  def type(%Assets.Asset{}, _), do: :asset
  def type(%Merge.Pool{}, _), do: :merge_pool

  defp decode_id(id) do
    case String.split(id, ":") do
      ["account", chain, address] ->
        try do
          {:ok,
           %Accounts.Layer1{
             id: id,
             chain: String.to_existing_atom(chain),
             address: address
           }}
        rescue
          ArgumentError -> {:error, "invalid chain #{chain}"}
        end

      ["account", address] ->
        {:ok, %Accounts.Account{id: id, chain: :thor, address: address}}

      ["asset", asset] ->
        RujiraWeb.Resolvers.Token.asset(%{asset: asset}, nil, nil)

      ["denom", denom] ->
        {:ok, %Denoms.Denom{id: id, denom: denom}}

      ["contract", "merge", address] ->
        RujiraWeb.Resolvers.Merge.node(%{address: address}, nil, nil)

      _ ->
        {:error, "Invalid ID"}
    end
  end

  def encode_id(:asset, asset), do: "asset:#{asset}"
  def encode_id(:account, address), do: "account:#{address}"
  def encode_id(:denom, denom), do: "denom:#{denom}"
  def encode_id(:account, chain, address), do: "account:#{chain}:#{address}"
  def encode_id(:contract, :merge, address), do: "contract:merge:#{address}"
end
