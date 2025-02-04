defmodule RujiraWeb.Resolvers.Node do
  alias Rujira.Assets
  alias Rujira.Denoms
  alias Rujira.Accounts
  alias Rujira.Merge
  alias Rujira.Fin
  alias Rujira.Staking

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
  def type(%Fin.Pair{}, _), do: :fin_pair
  def type(%Fin.Book{}, _), do: :fin_book
  def type(%Staking.Pool{}, _), do: :staking_pool

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

      ["contract", "fin", address] ->
        RujiraWeb.Resolvers.Fin.node(%{address: address}, nil, nil)

      ["contract", "fin", address, "book"] ->
        RujiraWeb.Resolvers.Fin.book(%{book: :not_loaded, address: address}, nil, nil)

      ["contract", "staking", address] ->
        RujiraWeb.Resolvers.Staking.node(%{address: address}, nil, nil)

      _ ->
        {:error, "Invalid ID"}
    end
  end

  def encode_id(:asset, asset), do: "asset:#{asset}"
  def encode_id(:account, address), do: "account:#{address}"
  def encode_id(:denom, denom), do: "denom:#{denom}"
  def encode_id(:account, chain, address), do: "account:#{chain}:#{address}"
  def encode_id(:contract, :merge, address), do: "contract:merge:#{address}"
  def encode_id(:contract, :staking, address), do: "contract:staking:#{address}"
  def encode_id(:contract, :fin, address), do: "contract:fin:#{address}"
  def encode_id(:contract, :fin, address, :book), do: "contract:fin:#{address}:book"
end
